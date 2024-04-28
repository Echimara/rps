<?php
// Include the database connection file
require_once 'connect.php';

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Retrieve the player name from the form
    $playerName = $_POST["player_name"];

    // Check if the player name is empty
    if (empty($playerName)) {
        echo "Player name is required.";
    } else {
        // Assuming you have a database or storage mechanism to track added players
        $existingPlayers = ["Alice", "Bob", "Charlie"]; // Example list of existing players

        // Check if the player name already exists
        if (in_array($playerName, $existingPlayers)) {
            echo "$playerName has already been added.";
        } else {
            // Add the player to the list or database (not implemented in this example)
            echo "$playerName was added successfully.";
        }
    }
} else {
    // Redirect to the form page if accessed directly without form submission
    header("Location: index.html");
    exit();
}
?>
