<?php

class Builder {
	private PDO $db;
	private array $schemaCache = [];
	private array $uniqueCache = [];

	public function __construct() {
		global $aspen_db;
		$this->db = $aspen_db;
	}

	public function build(string $table, array $overrides = [], int $seq = 0): bool|int {
		$columns = $this->columns($table);
		$uniqueCols = $this->uniqueColumns($table);
		$values = $overrides;
		foreach ($columns as $col) {
			$name = $col['Field'];
			if (array_key_exists($name, $values)) continue;
			if ($this->isAutoIncrement($col)) continue;
			if ($col['Null'] === 'YES') continue;
			if ($col['Default'] !== null && !in_array($name, $uniqueCols, true)) continue;
			$values[$name] = $this->defaultFor($col, in_array($name, $uniqueCols, true), $seq);
		}
		return $this->insert($table, $values);
	}

	private function columns(string $table): array {
		if (isset($this->schemaCache[$table])) return $this->schemaCache[$table];
		$stmt = $this->db->query("DESCRIBE `$table`");
		$cols = $stmt->fetchAll(PDO::FETCH_ASSOC);
		$this->schemaCache[$table] = $cols;
		return $cols;
	}

	private function uniqueColumns(string $table): array {
		if (isset($this->uniqueCache[$table])) return $this->uniqueCache[$table];
		$stmt = $this->db->prepare("SELECT DISTINCT COLUMN_NAME FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t AND NON_UNIQUE = 0 AND INDEX_NAME != 'PRIMARY'");
		$stmt->execute([':t' => $table]);
		$cols = $stmt->fetchAll(PDO::FETCH_COLUMN);
		$this->uniqueCache[$table] = $cols;
		return $cols;
	}

	private function isAutoIncrement(array $col): bool {
		return str_contains((string)($col['Extra'] ?? ''), 'auto_increment');
	}

	private function defaultFor(array $col, bool $unique, int $seq): mixed {
		$type = strtolower($col['Type']);
		$suffix = $unique ? sprintf('%06d', microtime(true) * 1000 + $seq) : '';
		if (str_starts_with($type, 'enum(')) {
			return $this->firstEnumValue($type);
		}
		if (preg_match('/^(tiny|small|medium|big)?int|^bit\\b/', $type)) {
			return $unique ? (int)microtime(true) * 1000 + $seq : 0;
		}
		if (str_starts_with($type, 'decimal') || str_starts_with($type, 'float') || str_starts_with($type, 'double')) return 0;
		if (str_starts_with($type, 'date') && !str_starts_with($type, 'datetime')) return '1970-01-01';
		if (str_starts_with($type, 'datetime') || str_starts_with($type, 'timestamp')) return '1970-01-01 00:00:00';
		if (str_starts_with($type, 'time')) return '00:00:00';
		return $unique ? "seed_$suffix" : '';
	}

	private function firstEnumValue(string $type): string {
		preg_match("/^enum\\('([^']*)'/", $type, $m);
		return $m[1] ?? '';
	}

	private function insert(string $table, array $values): bool|int {
		$cols = array_keys($values);
		$placeholders = array_map(fn($c) => ":$c", $cols);
		$sql = sprintf(
			'INSERT INTO `%s` (`%s`) VALUES (%s)',
			$table,
			implode('`,`', $cols),
			implode(',', $placeholders)
		);
		$stmt = $this->db->prepare($sql);
		foreach ($values as $k => $v) $stmt->bindValue(":$k", $v);
		try {
			$stmt->execute();
			return (int)$this->db->lastInsertId();
		} catch (PDOException $e) {
			fwrite(STDERR, "insert failed: " . $e->getMessage() . "\n  sql: $sql\n");
			return false;
		}
	}
}
