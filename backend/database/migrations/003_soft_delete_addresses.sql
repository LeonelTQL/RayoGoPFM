-- Añadir columna active a la tabla addresses para soportar borrado lógico
ALTER TABLE addresses ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;
