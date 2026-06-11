<?php

require_once __DIR__ . '/Builder.php';

abstract class BaseType {
	abstract public function name(): string;

	abstract public function table(): string;

	abstract public function identity(int $n): array;

	public function build(int $count, array $overrides = []): int {
		global $aspen_db;
		$builder = new Builder();
		$start = $this->nextIndex();
		$created = 0;
		for ($i = 0; $i < $count; $i++) {
			$n = $start + $i;
			$row = array_merge($this->identity($n), $overrides);
			$id = $builder->build($this->table(), $row, $n);
			if ($id === false) break;
			$created++;
		}
		return $created;
	}

	protected function nextIndex(): int {
		return 1;
	}
}
