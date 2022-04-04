seta: *.vala
	valac --vapidir="${HOME}/code/c/vte/_build/bindings/vala" --pkg posix --pkg gtk+-3.0 --target-glib 2.52.0 --pkg vte-2.91 *.vala -o seta
