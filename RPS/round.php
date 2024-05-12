<!-- Name: Chimara Okeke -->
<!DOCTYPE html>
<html>
<head>
    <style>
        .message {
            width: 100%;
            height: 50px;
            text-align: center;
        }
    </style>
        <title>Round PHP</title>
</head>
<body>
    
    <?php
    require 'connect.php';

    if (!$dbConn) 
    {
        die('Connection failed'); // check the connection
    }

    $pyr_1 = $_POST['pyr_1'];   // get input value from index.html
    $move_1 = $_POST['move_1'];
    $pyr_2 = $_POST['pyr_2']; 
    $move_2 = $_POST['move_2'];
    $comstring = "CALL proc_insert_round($1, $2, $3, $4, NULL)";

    // Execute the stored procedure
    $result = pg_query_params($dbConn, $comstring, array($pyr_1, $move_1, $pyr_2, $move_2));

    // Check that the procedure call was successful:
    if (!$result) 
    {
        die('Unable to CALL stored procedure: ' . pg_last_error());
    }

    $row = pg_fetch_row($result);
    $parm_out1 = $row[0];  // This is the first INOUT parameter
    $parm_out3 = $row[2];  

    // Error Codes:
    // 1 - Name already exists
    // 0 - Success

    if ($parm_out1 == 1) 
    {
        $output = 'The name ' . $pyr_1 . ' is in use.';

    } 
    elseif ($parm_out3 == 1) 
    {
        $output = 'The name ' . $pyr_2 . ' is in use.';

    } 
    elseif ($parm_out1 == 1 && $parm_out3 == 1) 
    {

        $output = 'The names ' . $pyr_1 . ' and ' . $pyr_2 . ' are in use.';

    }  
    else
    {
        $output = 'Round between ' . $pyr_1 . ' and ' . $pyr_2 . ' was successful.';
    }

    pg_close($dbConn);
    ?>

    <!-- Display the output & go back to start -->
    <form action="/index.html">
        <div>
            <textarea class="message" name="feedback" id="feedback" rows="1" cols="80" readonly="readonly"><?php echo $output; ?></textarea>
        </div>
        <button type="submit">Return</button>
    </form>
</body>
</html>
