function readfcn(filename) 
stored = load(filename)
variavel = erase(filename, ["'", ".mat"])
matrix = stored.(variavel) 
save(filename, 'matrix');
