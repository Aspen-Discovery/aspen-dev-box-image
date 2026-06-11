<?php

abstract class BaseType {
	abstract public function name(): string;

	abstract public function build(int $count, array $overrides = []): int;
}
