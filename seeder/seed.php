<?php

$args = array_slice($argv, 1);
$cmd = $args[0] ?? '';

$helpFlags = ['', 'help', '-h', '--help'];
if (in_array($cmd, $helpFlags, true)) {
	fwrite(STDERR, "usage: seed.php <command> [args...]\n  list\n  build <table> <count> [key=value ...]\n");
	exit($cmd === '' ? 1 : 0);
}

$_SERVER['aspen_server'] = getenv('SITE_NAME') ?: 'dev.localhost';

chdir('/usr/local/aspen-discovery/code/web');
require_once '/usr/local/aspen-discovery/code/web/bootstrap.php';
require_once __DIR__ . '/lib/BaseType.php';
require_once __DIR__ . '/lib/GenericType.php';

foreach (glob(__DIR__ . '/types/*.php') as $file) {
	require_once $file;
}

$customTypes = [];
foreach (get_declared_classes() as $class) {
	if (!is_subclass_of($class, 'BaseType')) continue;
	if ($class === 'GenericType') continue;
	$instance = new $class();
	$customTypes[$instance->name()] = $instance;
}

if ($cmd === 'list') {
	$tables = listTables();
	foreach ($tables as $table) {
		$marker = isset($customTypes[$table]) ? ' [custom]' : '';
		echo "$table$marker\n";
	}
	exit(0);
}

if ($cmd !== 'build') {
	fwrite(STDERR, "unknown command: $cmd\n");
	exit(1);
}

$target = $args[1] ?? '';
$count = (int)($args[2] ?? 0);

if ($target === '') {
	fwrite(STDERR, "build requires a table or type name\n");
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

$type = $customTypes[$target] ?? (tableExists($target) ? new GenericType($target) : null);

if ($type === null) {
	fwrite(STDERR, "unknown table or type: $target (try 'list')\n");
	exit(1);
}

$created = $type->build($count, $overrides);
echo "built $created of $count requested $target\n";

function listTables(): array {
	global $aspen_db;
	$stmt = $aspen_db->query("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME");
	$rows = $stmt->fetchAll(PDO::FETCH_COLUMN);
	return $rows;
}

function tableExists(string $name): bool {
	global $aspen_db;
	$stmt = $aspen_db->prepare("SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t");
	$stmt->execute([':t' => $name]);
	return (bool)$stmt->fetchColumn();
}
