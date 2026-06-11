<?php

class GenericType extends BaseType {
	private string $table;

	public function __construct(string $table) {
		$this->table = $table;
	}

	public function name(): string {
		return $this->table;
	}

	public function table(): string {
		return $this->table;
	}

	public function identity(int $n): array {
		return [];
	}
}
