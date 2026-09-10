use aegis::fault_tree::FaultTreeNode;

#[test]
fn independent_and_or_gates_match_closed_form() {
    let and = FaultTreeNode::And(vec![
        FaultTreeNode::BasicEvent { id: "a".into(), probability: 0.1 },
        FaultTreeNode::BasicEvent { id: "b".into(), probability: 0.2 },
    ]);
    assert!((and.evaluate().unwrap() - 0.02).abs() < 1e-14);

    let or = FaultTreeNode::Or(vec![
        FaultTreeNode::BasicEvent { id: "a".into(), probability: 0.1 },
        FaultTreeNode::BasicEvent { id: "b".into(), probability: 0.2 },
    ]);
    assert!((or.evaluate().unwrap() - 0.28).abs() < 1e-14);
}

#[test]
fn empty_gate_is_rejected() {
    assert!(FaultTreeNode::And(vec![]).evaluate().is_err());
}

#[test]
fn repeated_events_are_rejected_even_across_nested_gates() {
    let event = FaultTreeNode::BasicEvent { id: "shared".into(), probability: 0.1 };
    let tree = FaultTreeNode::Or(vec![
        event.clone(),
        FaultTreeNode::And(vec![event]),
    ]);
    assert!(tree.evaluate().is_err());
}
