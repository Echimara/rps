<!-- Name: Chimara Okeke -->
<!DOCTYPE html>
<html>
<head>
    <style>
        .message {
            width: 100%;
            height: 100px;
            resize: none;
            text-align: center; 
        }
    </style>
        <title>Player PHP</title>
</head>
<body>
    <?php
    require 'connect.php';
    if (!$dbConn) 
    {
        die('Connection failed'); // check the connection
    }

    $pyr = $_POST['pyr'];       // get input value from index.html
    $comstring = "CALL proc_insert_player($1, NULL)";

    // Execute the query - the actual function call to the SQL server
    $result = pg_query_params($dbConn, $comstring, array($pyr));

    // Check if the query was successful
    if (!$result) 
    {
        die('Unable to CALL stored procedure: ' . pg_last_error());
    }

    $row = pg_fetch_row($result);
    $parm_out = $row[0]; // this is the first INOUT parmeter. 
                                 

    // Error Codes:
    // 1 - Name already exists
    // 0 - Success

    // Parse the output based on the value of the output parameter:
    if ($parm_out == 1) {

        // errors in the procedure are detected here.
        $output = 'The name ' . $pyr . ' is in use.';

    } 
    else
    {

        $output = 'The name ' . $pyr . ' was added successfully.';

    } 

    pg_close($dbConn);
    ?>

    <!-- Display the output & go back to start -->
    <form action="/index.html">
        <div>
            <textarea class="message" name="feedback" id="feedback" rows=1 cols=80 readonly="enabled">
                <?php echo $output; ?>
            </textarea>
        </div>
        <button type="submit">Return</button>
    </form>
</body>
</html>
