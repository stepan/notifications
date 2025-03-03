reset-database:
	dropdb notifications || true
	createdb notifications
	psql notifications -f schema.sql