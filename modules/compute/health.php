<?php
header('Content-Type: application/json');
$response = array(
    'status' => 'UP',
    'date'=> date('c')
);
echo json_encode($response); 
?>