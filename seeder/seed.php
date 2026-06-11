<?php

$args = array_slice($argv, 1);
$cmd = $args[0] ?? '';

$helpFlags = ['', 'help', '-h', '--help'];
if (in_array($cmd, $helpFlags, true)) {
	fwrite(STDERR, "usage: seed.php <command> [args...]\n  list\n  build <type> <count> [key=value ...]\n");
	exit($cmd === '' ? 1 : 0);
}

chdir('/usr/local/aspen-discovery/code/web');
require_once '/usr/local/aspen-discovery/code/web/bootstrap.php';
require_once __DIR__ . '/lib/BaseType.php';

foreach (glob(__DIR__ . '/types/*.php') as $file) {
	require_once $file;
}

$types = [];
foreach (get_declared_classes() as $class) {
	if (!is_subclass_of($class, 'BaseType')) continue;
	$instance = new $class();
	$types[$instance->name()] = $instance;
}

if ($cmd === 'list') {
	foreach (array_keys($types) as $name) echo "$name\n";
	exit(0);
}

if ($cmd !== 'build') {
	fwrite(STDERR, "unknown command: $cmd\n");
	exit(1);
}

$type = $args[1] ?? '';
$count = (int)($args[2] ?? 0);

if (!isset($types[$type])) {
	fwrite(STDERR, "unknown type: $type (try 'list')\n");
	exit(1);
}

if ($count < 1) {
	fwrite(STDERR, "count must be >= 1\n");
	exit(1);
}

$overrides = [];
foreach (array_slice($args, 3) as $kv) {
	if (!str_contains($kv, '=')) continue;
	[$k, $v] = explode('=', $kv, 2);
	$overrides[$k] = $v;
}

$created = $types[$type]->build($count, $overrides);
echo "built $created of $count requested $type\n";
