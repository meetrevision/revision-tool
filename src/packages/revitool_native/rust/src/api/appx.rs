//! AppX package management over the WinRT deployment API.
//!
//! Exposes domain types to Dart without leaking WinRT types.

#![warn(missing_docs)]

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
pub fn is_service_account_sid(sid: &str) -> bool {
    matches!(sid, SYSTEM_SID | LOCAL_SERVICE_SID | NETWORK_SERVICE_SID)
}

/// Package installation state for a user.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
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
            state if state == WinInstallState::NotInstalled => Self::NotInstalled,
            state if state == WinInstallState::Staged => Self::Staged,
            state if state == WinInstallState::Installed => Self::Installed,
            state if state == WinInstallState::Paused => Self::Paused,
            state => Self::Other(state.0),
        }
    }
}

/// Package identity and naming information.
#[derive(Debug, Clone, PartialEq, Eq)]
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
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PackageUserState {
    /// User security identifier (SID).
    pub sid: String,
    /// Installation state for this user.
    pub install_state: InstallState,
}

/// Result of a removal or deprovisioning request.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RemovalOutcome {
    /// Package full name or family name targeted by the request.
    pub identifier: String,
    /// Deployment `HRESULT` return code. Zero indicates success.
    pub extended_error_code: u32,
    /// Error message, or empty when successful.
    pub error_text: String,
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
fn outcome_of(identifier: &str, result: &DeploymentResult) -> Result<RemovalOutcome> {
    Ok(RemovalOutcome {
        identifier: identifier.to_owned(),
        extended_error_code: result
            .ExtendedErrorCode()
            .context("DeploymentResult::ExtendedErrorCode")?
            .0 as u32,
        error_text: result
            .ErrorText()
            .context("DeploymentResult::ErrorText")?
            .to_string(),
    })
}

/// Lists all packages installed for any user.
pub async fn list_installed() -> Result<Vec<PackageIdentity>> {
    let packages = manager()?.FindPackages().context("FindPackages")?;
    collect_packages(&packages)
}

/// Finds packages matching `family_name` across all users.
pub async fn find_by_family_name(family_name: String) -> Result<Vec<PackageIdentity>> {
    let packages = manager()?
        .FindPackagesByPackageFamilyName(&HSTRING::from(family_name.as_str()))
        .context("FindPackagesByPackageFamilyName")?;
    collect_packages(&packages)
}

/// Lists machine-wide provisioned packages.
pub async fn list_provisioned() -> Result<Vec<PackageIdentity>> {
    let packages = manager()?
        .FindProvisionedPackages()
        .context("FindProvisionedPackages")?;
    collect_from_vector(&packages)
}

/// Lists user install states for `full_name`, including service accounts.
pub async fn find_users(full_name: String) -> Result<Vec<PackageUserState>> {
    let users = manager()?
        .FindUsers(&HSTRING::from(full_name.as_str()))
        .context("FindUsers")?;
    collect_users(&users)
}

/// Lists packages installed for user `sid`.
pub async fn list_for_user(sid: String) -> Result<Vec<PackageIdentity>> {
    let packages = manager()?
        .FindPackagesByUserSecurityId(&HSTRING::from(sid.as_str()))
        .context("FindPackagesByUserSecurityId")?;
    collect_packages(&packages)
}

/// Returns whether package removal is pending for the calling user.
pub async fn is_removal_pending(full_name: String) -> Result<bool> {
    manager()?
        .IsPackageRemovalPending(&HSTRING::from(full_name.as_str()))
        .context("IsPackageRemovalPending")
}

/// Returns whether package removal is pending for user `sid`.
pub async fn is_removal_pending_for_user(full_name: String, sid: String) -> Result<bool> {
    manager()?
        .IsPackageRemovalPendingForUser(
            &HSTRING::from(full_name.as_str()),
            &HSTRING::from(sid.as_str()),
        )
        .context("IsPackageRemovalPendingForUser")
}

/// Removes a package for the current user or all users.
pub async fn remove_package(
    full_name: String,
    all_users: bool,
    preserve_roamable: bool,
) -> Result<RemovalOutcome> {
    anyhow::ensure!(
        !(all_users && preserve_roamable),
        "PreserveRoamableApplicationData is not supported with RemoveForAllUsers"
    );
    let options = if all_users {
        RemovalOptions::RemoveForAllUsers
    } else if preserve_roamable {
        RemovalOptions::PreserveRoamableApplicationData
    } else {
        RemovalOptions::None
    };
    let result = manager()?
        .RemovePackageWithOptionsAsync(&HSTRING::from(full_name.as_str()), options)
        .context("RemovePackageWithOptionsAsync")?
        .await
        .context("RemovePackageWithOptionsAsync")?;
    outcome_of(&full_name, &result)
}

/// Deprovisions a package family across all users.
pub async fn deprovision_all_users(family_name: String) -> Result<RemovalOutcome> {
    let result = manager()?
        .DeprovisionPackageForAllUsersAsync(&HSTRING::from(family_name.as_str()))
        .context("DeprovisionPackageForAllUsersAsync")?
        .await
        .context("DeprovisionPackageForAllUsersAsync")?;
    outcome_of(&family_name, &result)
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
    fn reserved_slot_keeps_its_raw_number() {
        assert_eq!(
            InstallState::from(WinInstallState(4)),
            InstallState::Other(4)
        );
    }
}
