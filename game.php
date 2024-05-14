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
        <title>Game PHP</title>
</head>
<body>
    <?php
        require 'connect.php';

        if (!$dbConn) 
        {
            die('Connection failed');
        }

        $pyr_1 = $_POST['pyr_1'];
        $pyr_2 = $_POST['pyr_2'];
        $comstring = "CALL proc_insert_game($1, $2, NULL)";

        // Execute the stored procedure
        $result = pg_query_params($dbConn, $comstring, array($pyr_1, $pyr_2));
        
        // Check if the stored procedure call was successful
        if (!$result) 
        {
            die('Unable to CALL stored procedure: ' . pg_last_error());
        }

        $row = pg_fetch_row($result);
        $parm_out1 = $row[0];  // This is the first INOUT parameter
        $parm_out2 = $row[1];

        // Error Codes:
        // 1 - Name already exists
        // 0 - Success
        
        if ($parm_out1 == 1) 
        {
            $output = 'The name ' . $pyr_1 . ' is in use.';

        } 
        elseif ($parm_out2 == 1) 
        {
            $output = 'The name ' . $pyr_2 . ' is in use.';

        } 
        elseif ($parm_out1 == 1 && $parm_out2 == 1) 
        {

            $output = 'The names ' . $pyr_1 . ' and ' . $pyr_2 . ' are in use.';

        }  
        else
        {
            $output = 'The names ' . $pyr_1 . ' and ' . $pyr_2 . ' were successfully added.';
        }

        pg_close($dbConn);
    ?>

    <form action="/index.html">
        <div>
            <textarea class="message" name="feedback" style="text-align: center;" rows="1" cols="80" readonly>
                <?php echo $output; ?>
            </textarea>
        </div>
        <button type="submit">Return</button>
    </form>
</body>
</html>
