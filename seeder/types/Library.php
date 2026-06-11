<?php

require_once ROOT_DIR . '/sys/LibraryLocation/Library.php';

class LibrarySeeder extends BaseType {
	public function name(): string {
		return 'library';
	}

	public function build(int $count, array $overrides = []): int {
		$startIdx = $this->nextIndex();
		$created = 0;
		for ($i = 0; $i < $count; $i++) {
			$n = $startIdx + $i;
			$library = new Library();
			$library->subdomain = sprintf('seedlib%05d', $n);
			$library->displayName = sprintf('Seeded Library %d', $n);
			foreach ($overrides as $k => $v) $library->$k = $v;
			if ($library->insert()) $created++;
		}
		return $created;
	}

	private function nextIndex(): int {
		$probe = new Library();
		$probe->whereAdd("subdomain LIKE 'seedlib%'");
		$probe->orderBy('subdomain DESC');
		$probe->limit(0, 1);
		if (!$probe->find(true)) return 1;
		return ((int)substr($probe->subdomain, 7)) + 1;
	}
}
