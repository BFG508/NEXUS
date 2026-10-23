use aegis::markov::Ctmc;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let lambda = 1.0e-4;
    let mu = 1.0e-2;
    let model = Ctmc::new(vec![vec![-lambda, lambda], vec![mu, -mu]])?;
    let steady = model.steady_state(1.0e-12, 200_000)?;
    println!("operational={:.12}", steady[0]);
    println!("failed={:.12}", steady[1]);
    Ok(())
}
