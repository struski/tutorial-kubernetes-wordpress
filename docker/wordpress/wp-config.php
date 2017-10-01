<?php
/* ! Assumption: env var names and prefixes are uppercase ! */
// HTTPS protocol fix
if ($_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// UNCOMMENT IF YOU HAVE W3 Totla Cache plugin installe and activated
/** Enable W3 Total Cache */
//define('WP_CACHE', true); // Added by W3 Total Cache

//only prefixes named in $env_var_prefixes will be processed ( every string will be treated as uppercase)
$env_var_prefixes = array('WPVAR_');
//only prefixes named in $env_var_prefixes_to_remove will be removed from key names (  every string will be treated as uppercase )
$env_var_prefixes_to_remove = array('WPVAR_');
// IF YOU ARE MAKING CHANGES TO PREFIXES THEN DO NOT FORGET TO MODIFY table prefix setting below
$table_prefix = getenv('WPVAR_TABLE_PREFIX') ?: 'wp_';

foreach ($_ENV as $key => $value) {
    $key_length = strlen($key);
    $key_prefix = '';
    foreach ($env_var_prefixes as $prefix) {
        if (0 === strpos(strtoupper($key), strtoupper($prefix))) {
            $key_prefix = $prefix;
            break;
        }
    }

    if (!strlen($key_prefix) > 0) {
        // NOT an environment variable that should be processed
        continue;
    }

    // env var name without the prefix and capitalized
    $wp_env_name = strtoupper($key);
    if (in_array(strtoupper($key_prefix), array_map('strtoupper', $env_var_prefixes_to_remove))) {
        // prefix needs to be removed before define is called()
        $wp_env_name = substr($wp_env_name, strlen($key_prefix));
    }
    if (!defined($wp_env_name)) {
        define($wp_env_name, $value);
    }
}

if (!defined('ABSPATH'))
    define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');