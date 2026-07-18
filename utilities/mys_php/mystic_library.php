<?php

/* SVN FILE: $Id: mystic_library.php 7 2011-11-07 20:40:17Z frank $ */

/**
 * mystic_library.php : A set of functions to access mystic bbs data files
 *
 * @package mystic_library
 * @author $Author: frank $
 * @copyright $Copyright 2011 Frank Linhares/netsurge%demonic%bbs-scene.org$
 * @version $Revision: 7 $
 * @lastrevision $Date: 2011-11-07 15:40:17 -0500 (Mon, 07 Nov 2011) $
 * @modifiedby $LastChangedBy: frank $
 * @lastmodified $LastChangedDate: 2011-11-07 15:40:17 -0500 (Mon, 07 Nov 2011) $
 * @filesource $URL: http://miserybbs.com/svn/miserybbs/scripts/mystic_library.php $
*/
 
/**
 * mystic_library.php
 *
 * @package mystic_library
 *
 * This library is a collection of functions that are used to access and parse various data file from Mystic BBS 1.09+
 *
 * A description of each function and what they return is listed in the doc block for each function.
 *
 * Include this library in all pages that will be showing data from Mystic BBS like this:
 *
 * 		include "inc/mystic_library.php";
 *
 * Also set the path to Mystic's data directory like this:
 *
 *		$data_path = "/home/bbs/mystic/data/";
 *
 * Support for mystic_php_library can be found on the official support bbs, miserybbs.com
 *
**/
  
/**
 * read and parse last 10 callers from Mystic
 *
 * @uses: mystic_lastcallers(path to mystic data dir $var, number of last callers $var, "Y" to parse pipe colours or "N" to strip pipe colours "$")
 *
 * @return: an array containing the following keys identifying the last X callers; where X is set by $number. If no number is specified it will
 *		   display the the last ten callers:
 *
 * 		   user = username/handle
 *		   city = user's city
 *		   address = user's address
 *		   baud = baud rate user connected with
 *		   date = time and date of call
 *		   node = node number
 *		   caller = caller number
 *		   email = user's email address
 *		   info = user's usernote
 *		   opt1 = user's opt1 field
 *		   opt2 = user's opt2 field
 *		   opt3 = user's opt3 field
 *
 * @author: Frank Linhares
**/

function mystic_lastcallers($data_path, $number = 10, $pipe = "N")
{
	$pipe = strtoupper($pipe);        

	if ($number > 10)
	{
		$number = 10;
	}
	 
	$fp = fopen ($data_path.'callers.dat', 'rb');
	for ($i = 0; $i < $number; $i++) {
		$data = fread ($fp, 279);
   
		// Create a data structure
		
		$data_format =
			'Cuserlen/' .		# Get the length of the user field
			'A30user/' .		# Get the username (30) padded with null
			'Ccitylen/' .		# Get the length of the city field
			'A25city/' .		# Get the city (25) padded with null
			'Caddresslen/' .	# Get the length of the address field
			'A30address/' .		# Get the address (30) padded with null      
			'Cbaudlen/' .		# Get the length of the baud field
			'A6baud/' .	   	# Get the baud (10) padded with null
			'ldate/' .		# Get the date
			'Cnode/' .		# Get the node number
			'lcaller/' .		# Get the caller number
			'Cemaillen/' .		# Get the length of the email field
			'A35email/' .		# Get the email (35) padded with null
			'Cinfolen/' .		# Get the length of the usernote field
			'A30info/' .		# Get the usernote (30) padded with null
			'Copt1len/' .		# Get the length of the opt1 field
			'A35opt1/' .		# Get the opt1 field (35) padded with null
			'Copt2len/' .		# Get the length of the opt2 field
			'A35opt2/' .		# Get the opt2 field (35) padded with null
			'Copt3len/' .		# Get the length of the opt3 field
			'A35opt3/';		# Get the opt3 field (35) padded with null
     
		// Unpack the data structure
		
		$lcallers[] = unpack ($data_format, $data);
		
	}  
	
	// Change date from dos to readable and strip pipe codes 
	
	foreach ( $lcallers as &$lengfix ) {
		$lengfix['user'] = substr($lengfix['user'], 0, $lengfix['userlen']);
		$lengfix['city'] = substr($lengfix['city'], 0, $lengfix['citylen']);
		$lengfix['address'] = substr($lengfix['address'], 0, $lengfix['addresslen']);
		$lengfix['baud'] = substr($lengfix['baud'], 0, $lengfix['baudlen']);
		$lengfix['email'] = substr($lengfix['email'], 0, $lengfix['emaillen']);
		$lengfix['info'] = substr($lengfix['info'], 0, $lengfix['infolen']);
		$lengfix['opt1'] = substr($lengfix['opt1'], 0, $lengfix['opt1len']);
		$lengfix['opt2'] = substr($lengfix['opt2'], 0, $lengfix['opt2len']); 
		$lengfix['opt3'] = substr($lengfix['opt3'], 0, $lengfix['opt3len']);  

	}
	
	// remove length keys now that we have used them to trim their variables	
	
	foreach ( $lcallers as &$rfix ) {
		unset($rfix['userlen']);
		unset($rfix['citylen']);
		unset($rfix['addresslen']);
		unset($rfix['baudlen']);
		unset($rfix['emaillen']);
		unset($rfix['infolen']);
		unset($rfix['opt1len']);
		unset($rfix['opt2len']);
		unset($rfix['opt3len']);
	}			
	
	foreach ( $lcallers as &$dfix ) 
	{
		
		// change date from dos to unix and make human readable
		
		$dfix['date'] = dos2unixtime($dfix['date']);
		$dfix['date'] = date("Y-m-d H:i:s", $dfix['date']);
	}
	
	if ($pipe == "Y") {
		
		foreach ( $lcallers as &$dfix ) 
		{
			// convert pipe codes to proper colours
			
			$dfix['info'] = str_replace("|00", "<span class=\"pipe_00\">", $dfix['info']);
			$dfix['info'] = str_replace("|01", "<span class=\"pipe_01\">", $dfix['info']);
			$dfix['info'] = str_replace("|02", "<span class=\"pipe_02\">", $dfix['info']);
			$dfix['info'] = str_replace("|03", "<span class=\"pipe_03\">", $dfix['info']);
			$dfix['info'] = str_replace("|04", "<span class=\"pipe_04\">", $dfix['info']);
			$dfix['info'] = str_replace("|05", "<span class=\"pipe_05\">", $dfix['info']);
			$dfix['info'] = str_replace("|06", "<span class=\"pipe_06\">", $dfix['info']);
			$dfix['info'] = str_replace("|07", "<span class=\"pipe_07\">", $dfix['info']);
			$dfix['info'] = str_replace("|08", "<span class=\"pipe_08\">", $dfix['info']);
			$dfix['info'] = str_replace("|09", "<span class=\"pipe_09\">", $dfix['info']);
			$dfix['info'] = str_replace("|10", "<span class=\"pipe_10\">", $dfix['info']);
			$dfix['info'] = str_replace("|11", "<span class=\"pipe_11\">", $dfix['info']);
			$dfix['info'] = str_replace("|12", "<span class=\"pipe_12\">", $dfix['info']);
			$dfix['info'] = str_replace("|13", "<span class=\"pipe_13\">", $dfix['info']);
			$dfix['info'] = str_replace("|14", "<span class=\"pipe_14\">", $dfix['info']);
			$dfix['info'] = str_replace("|15", "<span class=\"pipe_15\">", $dfix['info']);
			$dfix['info'] = str_replace("|16", "", $dfix['info']);
			$dfix['info'] = str_replace("|17", "", $dfix['info']);
			$dfix['info'] = str_replace("|18", "", $dfix['info']);
			$dfix['info'] = str_replace("|19", "", $dfix['info']);
			$dfix['info'] = str_replace("|20", "", $dfix['info']);
			$dfix['info'] = str_replace("|21", "", $dfix['info']);
			$dfix['info'] = str_replace("|22", "", $dfix['info']);
			$dfix['info'] = str_replace("|23", "", $dfix['info']);
			$dfix['info'] = str_replace("|24", "", $dfix['info']);
		}
		
	}
	
	if ($pipe == "N") {
		
		foreach ( $lcallers as &$dfix ) 
		{			
			// convert pipe codes to proper colours	
			
			$dfix['info'] = str_replace("|00", "", $dfix['info']);
			$dfix['info'] = str_replace("|01", "", $dfix['info']);
			$dfix['info'] = str_replace("|02", "", $dfix['info']);
			$dfix['info'] = str_replace("|03", "", $dfix['info']);
			$dfix['info'] = str_replace("|04", "", $dfix['info']);
			$dfix['info'] = str_replace("|05", "", $dfix['info']);
			$dfix['info'] = str_replace("|06", "", $dfix['info']);
			$dfix['info'] = str_replace("|07", "", $dfix['info']);
			$dfix['info'] = str_replace("|08", "", $dfix['info']);
			$dfix['info'] = str_replace("|09", "", $dfix['info']);
			$dfix['info'] = str_replace("|10", "", $dfix['info']);
			$dfix['info'] = str_replace("|11", "", $dfix['info']);
			$dfix['info'] = str_replace("|12", "", $dfix['info']);
			$dfix['info'] = str_replace("|13", "", $dfix['info']);
			$dfix['info'] = str_replace("|14", "", $dfix['info']);
			$dfix['info'] = str_replace("|15", "", $dfix['info']);
			$dfix['info'] = str_replace("|16", "", $dfix['info']);
			$dfix['info'] = str_replace("|17", "", $dfix['info']);
			$dfix['info'] = str_replace("|18", "", $dfix['info']);
			$dfix['info'] = str_replace("|19", "", $dfix['info']);
			$dfix['info'] = str_replace("|20", "", $dfix['info']);
			$dfix['info'] = str_replace("|21", "", $dfix['info']);
			$dfix['info'] = str_replace("|22", "", $dfix['info']);
			$dfix['info'] = str_replace("|23", "", $dfix['info']);
			$dfix['info'] = str_replace("|24", "", $dfix['info']);			
		}
	}
	
	
	return $lcallers;
}

/**
 * read and parse Mystic's chat(#).dat file
 *
 * @uses: mystic_chat(path to mystic data dir $var, number of nodes you are running $int) 
 *
 * @return: an array containing the following keys identifying user information from each node. 
 *
 * 		   active = is anyone on the node. 1 = Yes, 0 = No
 *		   name = username/handle
 *		   action = user's current action
 *		   location = user's city and state
 *		   gender = user's gender. M = Male, F = Female
 *		   age = user's age
 *		   baud = user's connecting baud rate
 *		   invisible = user's invisibility status
 *		   available = user's availability status
 *		   inchat = is the user in multi-node chat. 1 = Yes, 0 = No
 *		   room = which multi-node chat room is the user in
 *
 * @author: Frank Linhares
 **/

function mystic_chat($data_path, $nodes)
{	

	// loop through the number of nodes with node1.dat, node2.dat, etc..
	
	for ($i = 1; $i <= $nodes; $i++) {
	
		$data = file_get_contents($data_path.'chat'.$i.'.dat');				
  
		// Create a data structure
		
		$data_format =
			'Cactive/' .     	# Get the date
			'Cnamelen/' .    	# Get the length of the name field 
			'A30name/' .	 	# Get the username (30) padded with null
			'Cactionlen/' .  	# Get the length of the action field 
			'A40action/' .	 	# Get the user's current action (40) padded with null		
			'Clocationlen/' .	# Get the length of the location field 
			'A30location/' . 	# Get the user's city and state (40) padded with null			
			'Agender/' . 	 	# Get the gender (m for male f for female)
			'Cage/' .		# Get the users age
			'Cbaudlen/' .    	# Get the length of the baud field 
			'A6baud/' . 	 	# Get the baud rate (6) padded with null
			'cinvisible/' .  	# Check if the user is invisible
			'cavailable/' .  	# Check if the user is available		
			'cinchat/' .     	# Check if the user is in multi-node chat		
			'Croom/' ;		# If in multi-node chat which room
		    
		// Unpack the data structure
		
		$mystic_chat[] = unpack ($data_format, $data);

	}
	
	// inject node number into array	
	
	for ($i = 0; $i <= $nodes; $i++) {
		$mystic_chat[$i]['node']=$i+1;
	}
	
	array_pop($mystic_chat);
	
	// trim and clean up strings
	
	foreach ( $mystic_chat as &$sfix ) {
		$sfix['name'] = substr($sfix['name'], 0, $sfix['namelen']);  
		$sfix['action'] = substr($sfix['action'], 0, $sfix['actionlen']); 
		$sfix['location'] = substr($sfix['location'], 0, $sfix['locationlen']);
		$sfix['baud'] = substr($sfix['baud'], 0, $sfix['baudlen']);
	}	
	
	// remove length keys now that we have used them to trim their variables	
	
	foreach ( $mystic_chat as &$rfix ) {
		unset($rfix['namelen']);
		unset($rfix['actionlen']);
		unset($rfix['locationlen']);
		unset($rfix['baudlen']);
	}
	
	// check if node is active, if not clear name and set action to "waiting for caller" 	
	
	foreach ( $mystic_chat as &$wfix ) {
		if ($wfix['active'] == 0) {
			$wfix['name'] = "";
			$wfix['action'] = 'waiting for caller';
		}
		
		// don't allow users who want to be invisible to be displayed.		
		
		if ($wfix['active'] == 1 AND $wfix['invisible'] == 1) {
			$wfix['name'] = "";
			$wfix['action'] = 'waiting for caller';
		}
	
	}	
	
	return $mystic_chat;
}

/**
 * read and parse Mystic's histor.dat file
 *
 * @uses: mystic_history(path to mystic data dir $var, "TODAY" to return todays stats only or "ALL" for all stats)
 * 
 * @return: an array containing the following keys identifying system stats. 
 *
 * 		   date = Date
 *		   emails = number of emails sent today
 *		   posts = number of posts today
 *		   downloads = number of downloads today
 *		   uploads = number of uploads today
 *		   dlkb = number of kilobytes downloaded today
 *		   ulkb = number of kilobytes uploaded today
 *		   newusers = number of new users today
 *		   calls = total number of calls today
 *
 * @author: Frank Linhares
 **/

function mystic_history($data_path, $total = "TODAY")
{	
	$total = strtoupper($total);	
	
	// get file size in order to determine how many records are stored
	
	$filesize = filesize($data_path.'history.dat'); 
	$record_length = 26;
	
	// divide file size by record length to determine number of records stored
	
	$record_number = $filesize / $record_length;
	
	// Open the mystic BBS data file in binary mode
	
	$fp = fopen ($data_path.'history.dat', 'rb');		
	
	for ($i = 0; $i < $record_number; $i++) {
		$data = fread ($fp, $record_length);
   
		/* Create a data structure */
		$data_format =
			'ldate/' .       # Get the date
			'Semails/' .     # Get the number of emails sent
			'Sposts/' .      # Get the number of posts
			'Sdownloads/' .  # Get the number of downloads
			'Suploads/' .    # Get the number of uploads
			'ldlkb/' .       # Get the number of downloaded kb
			'lupkb/' .       # Get the number of uploaded kb
			'ccalls/' .      # Get the number of calls
			'@24/' .	 # Jump to the 24th byte
			'snewusers/' ;   # Get the number of new users
     
		/* Unpack the data structure */
		$myshistory[] = unpack ($data_format, $data);	  	
     }  	   
     	 
	foreach ( $myshistory as &$dfix ) 
	{

	// change date from dos to unix and make human readable

	$dfix['date'] = dos2unixtime($dfix['date']);
	$dfix['date'] = date("Y-m-d H:i:s", $dfix['date']);
	$dfix['date'] = substr($dfix['date'], 0, 10);
			
	}

	// if only returning today's stats then only return the last entry	
	
	if ($total == "TODAY") {	
		$myshistory = end($myshistory);
	}
	
	return $myshistory;
}

/**
 * read and parse Mystic users.dat file
 * 
 * @uses: mystic_userlist(path to mystic data dir $var, "Y" to parse pipe colours or "N" to strip pipe colours "$")
 * 
 * @return: an array containing the following keys identifying users with accounts on the bbs. 
 *
 * 		   flags = account flags
 *		   handle = user's handle
 *		   realname = user's real name
 *		   password = user's password
 *		   address = user's address
 *		   city = user's city
 *		   zipcode = user's zip code
 *		   homephone = user's home phone
 *		   dataphone = user's data phone
 *		   bdate = user's birthdate
 *		   gender = user's gender
 *		   email = user's email address
 *		   opt1 = user's optional field 1
 *		   opt2 = user's optional field 2
 *		   opt3 = user's optional field 3
 *		   info = user's usernote
 *		   security = user's security level
 *		   smnu = user's start menu
 *		   firston = first time user on
 *		   laston = last time user on
 *		   calls = total number of calls
 *		   callstoday = total calls today
 *		   dls = total number of downloads
 *		   dlstoday = total number of downloads today
 *		   dlk = total number of downloads in k
 *		   dlktoday = total number of downloads today in k
 *		   uls = total number of uploads
 *		   ulsk = total number of uploads in k
 *		   posts = total number of posts for the user.
 *		   emails = total number of emails user has sent
 *		   timeleft = user's time left today
 *
 * @author: Frank Linhares
 **/

function mystic_userlist($data_path, $pipe = "N")
{	
	$pipe = strtoupper($pipe);	
	
	// get file size in order to determine how many records are stored
	
	$filesize = filesize($data_path.'users.dat'); 
	$record_length = 585;
	
	// divide file size by record length to determine number of records stored
	
	$record_number = $filesize / $record_length;
	
	// Open the mystic BBS data file in binary mode 
	
	$fp = fopen ($data_path.'users.dat', 'rb');		
	
	for ($i = 0; $i < $record_number; $i++) {
		$data = fread ($fp, $record_length);
   
		/* Create a data structure */
		$data_format =
			'Cflags/' . 		# Get the flags (byte)
			'Chandlelen/' .		# Get the length of the handle field 
			'A30handle/' .   	# Get the handle (30) padded with null
			'Crealnamelen/' .	# Get the length of the realname field 
			'A30realname/' .   	# Get the real name (30) padded with null      
			'Cpasswordlen/' .	# Get the length of the password field 
			'A15password/' .   	# Get the password (15) padded with null
			'Caddresslen/' .	# Get the length of the address field 
			'A30address/' .   	# Get the address (30) padded with null
			'Ccitylen/' .		# Get the length of the city field 
			'A25city/' .   		# Get the city (25) padded with null
			'Czipcodelen/' .	# Get the length of the zipcode field 
			'A9zipcode/' .		# Get the zipcode (9) padded with null
			'Chomephonelen/' .	# Get the length of the homephone field 
			'A15homephone/' .	# Get the home phone (15) padded with null
			'Cdataphonelen/' .	# Get the length of the dataphone field 
			'A15dataphone/' .	# Get the dataphone (15) padded with null
			'lbdate/' .   		# Get the birth date
			'Agender/' . 		# Get the gender (m for male f for female)
			'Cemaillen/' .		# Get the length of the email field 
			'A35email/' .		# Get the email address (35) padded with null
			'Copt1len/' .		# Get the length of the opt1 field 
			'A35opt1/' .		# Get the opt1 field (35) padded with null
			'Copt2len/' .		# Get the length of the opt2 field
			'A35opt2/' .		# Get the opt2 field (35) padded with null
			'Copt3len/' .		# Get the length of the opt3 field
			'A35opt3/'.		# Get the opt3 field (35) padded with null
			'Cinfolen/' .		# Get the length of the info field
			'A30info/' .		# Get the usernote (30) padded with null
			'@366/'.		# jump to the 367th btye
			'ssecurity/' .		# Get the security level
			'Csmnulen/' .		# Get the length of the smnu field
			'A8smnu/' .		# Get the start mnu field (8) padded with null
			'lfirston/' .		# Get the first on date
			'llaston/' .		# Get the last on date
			'lcalls/' .		# Get the number of calls
			'scallstoday/' .	# Get the # of calls today
			'sdls/' .		# Get the # of downloads
			'sdlstoday/' .		# Get the # of downloads today  
			'ldlk/' .		# Get the total downloads in k
			'ldlktoday/' .		# Get the total downloads in k today 
			'luls/' .		# Get the total # of uploads
			'lulk/' .		# Get the total uploads in k
			'lposts/' .		# Get the total posts
			'lemails/' .		# Get the total sent emails
			'ltimeleft/' ;		# Get the amount of time left today
     
		/* Unpack the data structure */
		$users[] = unpack ($data_format, $data);
		
     }  
	   
	// trim and clean up strings
	
	foreach ( $users as &$sfix ) {
		$sfix['handle'] = substr($sfix['handle'], 0, $sfix['handlelen']);  
		$sfix['realname'] = substr($sfix['realname'], 0, $sfix['realnamelen']); 
		$sfix['password'] = substr($sfix['password'], 0, $sfix['passwordlen']);
		$sfix['address'] = substr($sfix['address'], 0, $sfix['addresslen']);
		$sfix['city'] = substr($sfix['city'], 0, $sfix['citylen']);
		$sfix['zipcode'] = substr($sfix['zipcode'], 0, $sfix['zipcodelen']);
		$sfix['homephone'] = substr($sfix['homephone'], 0, $sfix['homephonelen']);
		$sfix['dataphone'] = substr($sfix['dataphone'], 0, $sfix['dataphonelen']);
		$sfix['email'] = substr($sfix['email'], 0, $sfix['emaillen']);
		$sfix['opt1'] = substr($sfix['opt1'], 0, $sfix['opt1len']);
		$sfix['opt2'] = substr($sfix['opt2'], 0, $sfix['opt2len']);
		$sfix['opt3'] = substr($sfix['opt3'], 0, $sfix['opt3len']);
		$sfix['info'] = substr($sfix['info'], 0, $sfix['infolen']);
		
	}

	// remove length keys now that we have used them to trim their variables	
	
	foreach ( $users as &$rfix ) {
		unset($rfix['handlelen']);
		unset($rfix['realnamelen']);
		unset($rfix['passwordlen']);
		unset($rfix['addresslen']);
		unset($rfix['citylen']);
		unset($rfix['zipcodelen']);
		unset($rfix['homephonelen']);
		unset($rfix['dataphonelen']);
		unset($rfix['emaillen']);		
		unset($rfix['opt1len']);
		unset($rfix['opt2len']);
		unset($rfix['opt3len']);
		unset($rfix['infolen']);
	}	
	
	foreach ( $users as &$dfix ) 
	{		
		// change date from dos to unix and make human readable
		$dfix['firston'] = dos2unixtime($dfix['firston']);
		$dfix['firston'] = date("Y-m-d H:i:s", $dfix['firston']);
		
		$dfix['laston'] = dos2unixtime($dfix['laston']);
		$dfix['laston'] = date("Y-m-d H:i:s", $dfix['laston']);
		
		$dfix['bdate'] = jdtogregorian($dfix['bdate']);

	}
	
	if ($pipe == "Y") {
		
		foreach ( $users as &$dfix ) 
		{
			// convert pipe codes to proper colours
			$dfix['info'] = str_replace("|00", "<span class=\"pipe_00\">", $dfix['info']);
			$dfix['info'] = str_replace("|01", "<span class=\"pipe_01\">", $dfix['info']);
			$dfix['info'] = str_replace("|02", "<span class=\"pipe_02\">", $dfix['info']);
			$dfix['info'] = str_replace("|03", "<span class=\"pipe_03\">", $dfix['info']);
			$dfix['info'] = str_replace("|04", "<span class=\"pipe_04\">", $dfix['info']);
			$dfix['info'] = str_replace("|05", "<span class=\"pipe_05\">", $dfix['info']);
			$dfix['info'] = str_replace("|06", "<span class=\"pipe_06\">", $dfix['info']);
			$dfix['info'] = str_replace("|07", "<span class=\"pipe_07\">", $dfix['info']);
			$dfix['info'] = str_replace("|08", "<span class=\"pipe_08\">", $dfix['info']);
			$dfix['info'] = str_replace("|09", "<span class=\"pipe_09\">", $dfix['info']);
			$dfix['info'] = str_replace("|10", "<span class=\"pipe_10\">", $dfix['info']);
			$dfix['info'] = str_replace("|11", "<span class=\"pipe_11\">", $dfix['info']);
			$dfix['info'] = str_replace("|12", "<span class=\"pipe_12\">", $dfix['info']);
			$dfix['info'] = str_replace("|13", "<span class=\"pipe_13\">", $dfix['info']);
			$dfix['info'] = str_replace("|14", "<span class=\"pipe_14\">", $dfix['info']);
			$dfix['info'] = str_replace("|15", "<span class=\"pipe_15\">", $dfix['info']);
			$dfix['info'] = str_replace("|16", "", $dfix['info']);
			$dfix['info'] = str_replace("|17", "", $dfix['info']);
			$dfix['info'] = str_replace("|18", "", $dfix['info']);
			$dfix['info'] = str_replace("|19", "", $dfix['info']);
			$dfix['info'] = str_replace("|20", "", $dfix['info']);
			$dfix['info'] = str_replace("|21", "", $dfix['info']);
			$dfix['info'] = str_replace("|22", "", $dfix['info']);
			$dfix['info'] = str_replace("|23", "", $dfix['info']);
			$dfix['info'] = str_replace("|24", "", $dfix['info']);
		}
		
	}
	
	if ($pipe == "N") {
		
		foreach ( $users as &$dfix ) 
		{			
			// convert pipe codes to proper colours	
			$dfix['info'] = str_replace("|00", "", $dfix['info']);
			$dfix['info'] = str_replace("|01", "", $dfix['info']);
			$dfix['info'] = str_replace("|02", "", $dfix['info']);
			$dfix['info'] = str_replace("|03", "", $dfix['info']);
			$dfix['info'] = str_replace("|04", "", $dfix['info']);
			$dfix['info'] = str_replace("|05", "", $dfix['info']);
			$dfix['info'] = str_replace("|06", "", $dfix['info']);
			$dfix['info'] = str_replace("|07", "", $dfix['info']);
			$dfix['info'] = str_replace("|08", "", $dfix['info']);
			$dfix['info'] = str_replace("|09", "", $dfix['info']);
			$dfix['info'] = str_replace("|10", "", $dfix['info']);
			$dfix['info'] = str_replace("|11", "", $dfix['info']);
			$dfix['info'] = str_replace("|12", "", $dfix['info']);
			$dfix['info'] = str_replace("|13", "", $dfix['info']);
			$dfix['info'] = str_replace("|14", "", $dfix['info']);
			$dfix['info'] = str_replace("|15", "", $dfix['info']);
			$dfix['info'] = str_replace("|16", "", $dfix['info']);
			$dfix['info'] = str_replace("|17", "", $dfix['info']);
			$dfix['info'] = str_replace("|18", "", $dfix['info']);
			$dfix['info'] = str_replace("|19", "", $dfix['info']);
			$dfix['info'] = str_replace("|20", "", $dfix['info']);
			$dfix['info'] = str_replace("|21", "", $dfix['info']);
			$dfix['info'] = str_replace("|22", "", $dfix['info']);
			$dfix['info'] = str_replace("|23", "", $dfix['info']);
			$dfix['info'] = str_replace("|24", "", $dfix['info']);			
		}
	}	
	
	return $users;
}

/**
 * convert mystic's dos julien based time to unix time
 * 
 * @uses: dos2unixtime(dostime $var)
 * 
 * @return: unix time 
 *
 * @author: Frank Linhares
 **/

function dos2unixtime($dostime)
{
	$sec  = 2 * ($dostime & 0x1f);
	$min  = ($dostime >> 5) & 0x3f;
	$hrs  = ($dostime >> 11) & 0x1f;
	$day  = ($dostime >> 16) & 0x1f;
	$mon  = (($dostime >> 21) & 0x0f);
	$year = (($dostime >> 25) & 0x7f) + 1980;

	return mktime($hrs, $min, $sec, $mon, $day, $year);
}

/**
 * calculate a user's birthday
 * 
 * @uses: age(birthday $var)
 * 
 * @return: age
 *
 * @author: Frank Linhares
 **/

function age($birthday)
{
	return floor((time() - strtotime($birthday))/31556926);
}

?>
