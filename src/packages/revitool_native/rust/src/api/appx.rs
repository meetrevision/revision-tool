//! `AppX` package management over the `WinRT` deployment API.
//!
//! Exposes domain types to Dart without leaking `WinRT` types.

use anyhow::{Context, Result};
use windows::core::{RuntimeType, HSTRING};
use windows::ApplicationModel::Package;
use windows::Management::Deployment::{
    DeploymentResult, PackageInstallState as WinInstallState, PackageManager,
    PackageUserInformation, RemovalOptions,
};
use windows_collections::{IIterable, IIterator, IVector};

const SYSTEM_SID: &str = "S-1-5-18";
const LOCAL_SERVICE_SID: &str = "S-1-5-19";
const NETWORK_SERVICE_SID: &str = "S-1-5-20";

/// Returns whether `sid` is a built-in service account.
///
/// Filters out SYSTEM, LocalService, and NetworkService SIDs returned by
/// [`find_users`].
#[must_use]
#[flutter_rust_bridge::frb(sync)]
pub fn is_service_account_sid(sid: &str) -> bool {
    matches!(sid, SYSTEM_SID | LOCAL_SERVICE_SID | NETWORK_SERVICE_SID)
}

/// Package installation state for a user.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum InstallState {
    /// Not registered for this user.
    NotInstalled,
    /// Files staged but not registered.
    Staged,
    /// Registered and runnable.
    Installed,
    /// Registered but suspended.
    Paused,
    /// Unmapped state preserving the raw Windows value.
    Other(i32),
}

impl From<WinInstallState> for InstallState {
    fn from(value: WinInstallState) -> Self {
        match value {
            WinInstallState::NotInstalled => Self::NotInstalled,
            WinInstallState::Staged => Self::Staged,
            WinInstallState::Installed => Self::Installed,
            WinInstallState::Paused => Self::Paused,
            state => Self::Other(state.0),
        }
    }
}

/// Package identity and naming information.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct PackageIdentity {
    /// Full package name in `Name.Version.Architecture_PublisherId` format.
    pub full_name: String,
    /// Package name without version or publisher.
    pub name: String,
    /// Package family name in `Name_PublisherId` format.
    pub family_name: String,
    /// Publisher identifier hash.
    pub publisher_id: String,
    /// Whether the package is a shared framework.
    pub is_framework: bool,
}

/// Package installation state for a user.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct PackageUserState {
    /// User security identifier (SID).
    pub sid: String,
    /// Installation state for this user.
    pub install_state: InstallState,
}

impl PackageUserState {
    /// Returns whether this user SID is a built-in service account.
    #[must_use]
    #[flutter_rust_bridge::frb(sync)]
    pub fn is_service_account(&self) -> bool {
        is_service_account_sid(&self.sid)
    }
}

/// Scope and data preservation options for package removal.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum PackageRemovalScope {
    /// Removes the package for the calling user.
    #[default]
    CurrentUser,
    /// Removes the package for the calling user while retaining roamable data.
    CurrentUserPreserveRoamable,
    /// Removes the package for all users on the machine.
    AllUsers,
}

/// Result of a removal or deprovisioning request.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct RemovalOutcome {
    /// Package full name or family name targeted by the request.
    pub identifier: String,
    /// Deployment `HRESULT` return code. Zero indicates success.
    pub extended_error_code: u32,
    /// Error message, or empty when successful.
    pub error_text: String,
}

impl RemovalOutcome {
    /// Returns whether the removal succeeded without error.
    #[must_use]
    #[flutter_rust_bridge::frb(sync)]
    pub const fn is_success(&self) -> bool {
        self.extended_error_code == 0
    }
}

// PackageManager is agile; no COM apartment initialization needed.
fn manager() -> Result<PackageManager> {
    PackageManager::new().context("PackageManager::new")
}

// Drives IIterator manually to propagate COM errors instead of dropping them.
fn collect<T, R>(iterator: &IIterator<T>, mut map: impl FnMut(&T) -> Result<R>) -> Result<Vec<R>>
where
    T: RuntimeType + 'static,
{
    let mut collected = Vec::new();
    while iterator.HasCurrent().context("IIterator::HasCurrent")? {
        collected.push(map(&iterator.Current().context("IIterator::Current")?)?);
        iterator.MoveNext().context("IIterator::MoveNext")?;
    }
    Ok(collected)
}

fn identity_of(package: &Package) -> Result<PackageIdentity> {
    let id = package.Id().context("Package::Id")?;
    Ok(PackageIdentity {
        full_name: id.FullName().context("PackageId::FullName")?.to_string(),
        name: id.Name().context("PackageId::Name")?.to_string(),
        family_name: id
            .FamilyName()
            .context("PackageId::FamilyName")?
            .to_string(),
        publisher_id: id
            .PublisherId()
            .context("PackageId::PublisherId")?
            .to_string(),
        is_framework: package.IsFramework().context("Package::IsFramework")?,
    })
}

// Collects package identities from an IVector.
fn collect_from_vector(packages: &IVector<Package>) -> Result<Vec<PackageIdentity>> {
    let iterator = packages.First().context("IVector::First")?;
    collect(&iterator, identity_of)
}

fn collect_packages(packages: &IIterable<Package>) -> Result<Vec<PackageIdentity>> {
    let iterator = packages.First().context("IIterable::First")?;
    collect(&iterator, identity_of)
}

fn collect_users(users: &IIterable<PackageUserInformation>) -> Result<Vec<PackageUserState>> {
    let iterator = users.First().context("IIterable::First")?;
    collect(&iterator, |user| {
        Ok(PackageUserState {
            sid: user
                .UserSecurityId()
                .context("PackageUserInformation::UserSecurityId")?
                .to_string(),
            install_state: user
                .InstallState()
                .context("PackageUserInformation::InstallState")?
                .into(),
        })
    })
}

// Converts DeploymentResult into RemovalOutcome using ExtendedErrorCode.
#[expect(
    clippy::cast_sign_loss,
    reason = "HRESULT failure codes have the sign bit set; u32 preserves the raw 32-bit error code representation"
)]
fn outcome_of(identifier: &str, result: &DeploymentResult) -> Result<RemovalOutcome> {
    let hr = result
        .ExtendedErrorCode()
        .context("DeploymentResult::ExtendedErrorCode")?;
    Ok(RemovalOutcome {
        identifier: identifier.to_owned(),
        extended_error_code: hr.0 as u32,
        error_text: result
            .ErrorText()
            .context("DeploymentResult::ErrorText")?
            .to_string(),
    })
}

/// Lists all packages installed for any user.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if the
/// package enumeration query fails.
pub fn list_installed() -> Result<Vec<PackageIdentity>> {
    let packages = manager()?.FindPackages().context("FindPackages")?;
    collect_packages(&packages)
}

/// Finds packages matching `family_name` across all users.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if the
/// family lookup query fails.
pub fn find_by_family_name(family_name: &str) -> Result<Vec<PackageIdentity>> {
    let packages = manager()?
        .FindPackagesByPackageFamilyName(&HSTRING::from(family_name))
        .context("FindPackagesByPackageFamilyName")?;
    collect_packages(&packages)
}

/// Lists machine-wide provisioned packages.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if the
/// provisioned packages query fails.
pub fn list_provisioned() -> Result<Vec<PackageIdentity>> {
    let packages = manager()?
        .FindProvisionedPackages()
        .context("FindProvisionedPackages")?;
    collect_from_vector(&packages)
}

/// Lists user install states for `full_name`, including service accounts.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if the
/// user query fails.
pub fn find_users(full_name: &str) -> Result<Vec<PackageUserState>> {
    let users = manager()?
        .FindUsers(&HSTRING::from(full_name))
        .context("FindUsers")?;
    collect_users(&users)
}

/// Finds packages in family `family_name` installed for the calling user.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if the
/// user-specific family lookup fails.
pub fn find_for_current_user(family_name: &str) -> Result<Vec<PackageIdentity>> {
    // An empty security ID means the calling user.
    let packages = manager()?
        .FindPackagesByUserSecurityIdPackageFamilyName(&HSTRING::new(), &HSTRING::from(family_name))
        .context("FindPackagesByUserSecurityIdPackageFamilyName")?;
    collect_packages(&packages)
}

/// Lists the Application User Model IDs of the apps in `full_name` that are
/// installed for the calling user, in Start menu order.
///
/// Launch one with `explorer.exe shell:AppsFolder\<id>`, which also starts it
/// unelevated when the caller runs as administrator.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if
/// querying the app list entries fails. Returns an empty list if the
/// package is not installed for the calling user.
pub async fn app_user_model_ids(full_name: &str) -> Result<Vec<String>> {
    let package = match manager()?
        .FindPackageByUserSecurityIdPackageFullName(&HSTRING::new(), &HSTRING::from(full_name))
    {
        Ok(pkg) => pkg,
        // WinRT returns S_OK with a null pointer when the package is missing,
        // which windows-core converts to an Error with HRESULT 0.
        Err(e) if e.code().0 == 0 => return Ok(Vec::new()),
        Err(e) => return Err(e).context("FindPackageByUserSecurityIdPackageFullName"),
    };
    let entries = package
        .GetAppListEntriesAsync()
        .context("Package::GetAppListEntriesAsync")?
        .await
        .context("Package::GetAppListEntriesAsync")?;
    let iterator = entries.First().context("IVectorView::First")?;
    collect(&iterator, |entry| {
        Ok(entry
            .AppUserModelId()
            .context("AppListEntry::AppUserModelId")?
            .to_string())
    })
}

/// Lists packages installed for user `sid`.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if
/// querying packages for the user fails.
pub fn list_for_user(sid: &str) -> Result<Vec<PackageIdentity>> {
    let packages = manager()?
        .FindPackagesByUserSecurityId(&HSTRING::from(sid))
        .context("FindPackagesByUserSecurityId")?;
    collect_packages(&packages)
}

/// Returns whether package removal is pending for the calling user.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if
/// checking the removal status fails.
pub fn is_removal_pending(full_name: &str) -> Result<bool> {
    manager()?
        .IsPackageRemovalPending(&HSTRING::from(full_name))
        .context("IsPackageRemovalPending")
}

/// Returns whether package removal is pending for user `sid`.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if
/// checking the user removal status fails.
pub fn is_removal_pending_for_user(full_name: &str, sid: &str) -> Result<bool> {
    manager()?
        .IsPackageRemovalPendingForUser(&HSTRING::from(full_name), &HSTRING::from(sid))
        .context("IsPackageRemovalPendingForUser")
}

/// Removes a package for the specified scope.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if
/// initiating the removal operation fails.
pub async fn remove_package(full_name: &str, scope: PackageRemovalScope) -> Result<RemovalOutcome> {
    let options = match scope {
        PackageRemovalScope::CurrentUser => RemovalOptions::None,
        PackageRemovalScope::CurrentUserPreserveRoamable => {
            RemovalOptions::PreserveRoamableApplicationData
        }
        PackageRemovalScope::AllUsers => RemovalOptions::RemoveForAllUsers,
    };
    let result = manager()?
        .RemovePackageWithOptionsAsync(&HSTRING::from(full_name), options)
        .context("RemovePackageWithOptionsAsync")?
        .await
        .context("RemovePackageWithOptionsAsync")?;
    outcome_of(full_name, &result)
}

/// Deprovisions a package family across all users.
///
/// # Errors
///
/// Returns an error if the package manager cannot be initialized or if
/// initiating the deprovisioning operation fails.
pub async fn deprovision_all_users(family_name: &str) -> Result<RemovalOutcome> {
    let result = manager()?
        .DeprovisionPackageForAllUsersAsync(&HSTRING::from(family_name))
        .context("DeprovisionPackageForAllUsersAsync")?
        .await
        .context("DeprovisionPackageForAllUsersAsync")?;
    outcome_of(family_name, &result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn system_sid_is_a_service_account() {
        assert!(is_service_account_sid(SYSTEM_SID));
    }

    #[test]
    fn local_service_sid_is_a_service_account() {
        assert!(is_service_account_sid(LOCAL_SERVICE_SID));
    }

    #[test]
    fn network_service_sid_is_a_service_account() {
        assert!(is_service_account_sid(NETWORK_SERVICE_SID));
    }

    #[test]
    fn interactive_user_sid_is_not_a_service_account() {
        assert!(!is_service_account_sid("S-1-5-21-1000-2000-3000-1001"));
    }

    #[test]
    fn unknown_sid_is_not_a_service_account() {
        assert!(!is_service_account_sid("not-a-sid"));
    }

    #[test]
    fn installed_state_maps_to_named_variant() {
        assert_eq!(
            InstallState::from(WinInstallState::Installed),
            InstallState::Installed
        );
    }

    #[test]
    fn staged_state_maps_to_named_variant() {
        assert_eq!(
            InstallState::from(WinInstallState::Staged),
            InstallState::Staged
        );
    }

    #[test]
    fn not_installed_state_maps_to_named_variant() {
        assert_eq!(
            InstallState::from(WinInstallState::NotInstalled),
            InstallState::NotInstalled
        );
    }

    #[test]
    fn paused_state_maps_to_named_variant() {
        assert_eq!(
            InstallState::from(WinInstallState::Paused),
            InstallState::Paused
        );
    }

    #[test]
    fn reserved_slot_keeps_its_raw_number() {
        assert_eq!(
            InstallState::from(WinInstallState(4)),
            InstallState::Other(4)
        );
    }

    #[test]
    fn removal_outcome_success_predicate() {
        let success = RemovalOutcome {
            identifier: "pkg".to_string(),
            extended_error_code: 0,
            error_text: String::new(),
        };
        assert!(success.is_success());

        let failure = RemovalOutcome {
            identifier: "pkg".to_string(),
            extended_error_code: 0x8007_0005,
            error_text: "Access denied".to_string(),
        };
        assert!(!failure.is_success());
    }

    #[test]
    fn package_user_state_service_account_predicate() {
        let service_user = PackageUserState {
            sid: SYSTEM_SID.to_string(),
            install_state: InstallState::Installed,
        };
        assert!(service_user.is_service_account());

        let regular_user = PackageUserState {
            sid: "S-1-5-21-100-200-300".to_string(),
            install_state: InstallState::Installed,
        };
        assert!(!regular_user.is_service_account());
    }

    #[test]
    fn package_removal_scope_defaults_to_current_user() {
        assert_eq!(
            PackageRemovalScope::default(),
            PackageRemovalScope::CurrentUser
        );
    }

    #[test]
    fn nonexistent_package_app_user_model_ids_returns_empty_list() {
        let result = futures::executor::block_on(app_user_model_ids(
            "NonExistentPackage_1.0.0.0_x64__1234567890",
        ));
        assert!(
            result.is_ok(),
            "Expected Ok for missing package, got: {result:?}"
        );
        assert!(result.unwrap().is_empty());
    }
}
