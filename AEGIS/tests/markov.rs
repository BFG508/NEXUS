use aegis::markov::Ctmc;

#[test]
fn two_state_steady_state_matches_availability() {
    let lambda = 1e-4;
    let mu = 1e-2;
    let model = Ctmc::new(vec![vec![-lambda, lambda], vec![mu, -mu]]).unwrap();
    let steady = model.steady_state(1e-12, 200_000).unwrap();
    let expected = mu / (lambda + mu);
    assert!((steady[0] - expected).abs() < 1e-9);
    assert!((steady.iter().sum::<f64>() - 1.0).abs() < 1e-12);
}

#[test]
fn transient_distribution_is_normalized() {
    let model = Ctmc::new(vec![vec![-0.1, 0.1], vec![0.2, -0.2]]).unwrap();
    let transient = model.transient(&[1.0, 0.0], 5.0, 1e-12, 1000).unwrap();
    assert!((transient.iter().sum::<f64>() - 1.0).abs() < 1e-12);
    assert!(transient.iter().all(|p| (0.0..=1.0).contains(p)));
}

#[test]
fn malformed_generator_is_rejected() {
    assert!(Ctmc::new(vec![vec![-0.1, 0.2], vec![0.1, -0.1]]).is_err());
}
