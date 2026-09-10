use aegis::fault_tree::FaultTreeNode;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let tree = FaultTreeNode::Or(vec![
        FaultTreeNode::BasicEvent {
            id: "power_loss".to_string(),
            probability: 0.01,
        },
        FaultTreeNode::And(vec![
            FaultTreeNode::BasicEvent {
                id: "computer_a".to_string(),
                probability: 0.02,
            },
            FaultTreeNode::BasicEvent {
                id: "computer_b".to_string(),
                probability: 0.02,
            },
        ]),
    ]);
    println!("top_event_probability={:.10}", tree.evaluate()?);
    Ok(())
}
