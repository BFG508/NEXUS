use crate::error::AegisError;
use crate::models::Component;

pub fn component_mttf_hours(component: &Component) -> Result<f64, AegisError> {
    component.mttf_hours()
}

pub fn component_steady_state_availability(component: &Component) -> Result<Option<f64>, AegisError> {
    component.steady_state_availability()
}
