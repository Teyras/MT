SELECT 
    sub.id,
    sub.submitted_at, 
    eval.evaluated_at,
    sol.runtime_environment_id,
    ahwg.hardware_group_id,
    IF(EXISTS(
      SELECT * 
      FROM test_result res 
      WHERE res.solution_evaluation_id = eval.id AND status <> "OK"
    ), 1, 0) AS failed,
    RANK() OVER (ORDER BY asg.id) AS assignment_id,
    RANK() OVER (ORDER BY asg.exercise_id) AS exercise_id,
    asg.created_at as assigned_at,
    asg.first_deadline,
    asg.second_deadline,
    RANK() OVER (ORDER BY sol.author_id) AS author_id
  FROM assignment_solution_submission sub
  LEFT JOIN solution_evaluation eval ON sub.evaluation_id = eval.id
  LEFT JOIN assignment_solution asol ON sub.assignment_solution_id = asol.id
  LEFT JOIN assignment asg ON asol.assignment_id = asg.id
  LEFT JOIN solution sol ON asol.solution_id = sol.id
  LEFT JOIN assignment_hardware_group ahwg ON asg.id = ahwg.assignment_id
  WHERE YEAR(sub.submitted_at) >= 2018

  ORDER BY sub.submitted_at
