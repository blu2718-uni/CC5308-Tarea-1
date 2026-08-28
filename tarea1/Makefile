# Tarea 1 — CC5308 · Utilitarios de administración en Bash
#
# Utilidades para empaquetar la solución de referencia y ejecutar el evaluador.

.PHONY: help solution check clean

help:
	@printf 'Tarea 1 (CC5308)\n'
	@printf '  make solution   empaqueta la solución de referencia en solution.tar.gz\n'
	@printf '  make check      ejecuta el evaluador (check.sh) sobre solution.tar.gz\n'
	@printf '  make clean      elimina artefactos generados\n'

solution:
	tar -czf solution.tar.gz -C solution .

check: solution
	./check.sh solution.tar.gz

clean:
	rm -f solution.tar.gz
