<?php

class LibrarySeeder extends BaseType {
	public function name(): string {
		return 'library';
	}

	public function table(): string {
		return 'library';
	}

	public function identity(int $n): array {
		return [
			'subdomain' => sprintf('seedlib%05d', $n),
			'displayName' => sprintf('Seeded Library %d', $n),
		];
	}

	protected function nextIndex(): int {
		global $aspen_db;
		$stmt = $aspen_db->query("SELECT subdomain FROM library WHERE subdomain LIKE 'seedlib%' ORDER BY subdomain DESC LIMIT 1");
		$row = $stmt->fetch(PDO::FETCH_ASSOC);
		if (!$row) return 1;
		return ((int)substr($row['subdomain'], 7)) + 1;
	}
}
