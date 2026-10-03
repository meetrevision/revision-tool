#![deny(missing_docs)]

//! Native bridge for Revision Tool.
//!
//! Exposes domain operations over the Windows API. See [`api::appx`] for
//! package management.

pub mod api;
mod frb_generated;
