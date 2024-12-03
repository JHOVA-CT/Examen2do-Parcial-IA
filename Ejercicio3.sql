DECLARE 
    @longitud INT, -- Longitud de los nombres a comparar
    @contador INT, -- Contador para las iteraciones
    @caracter VARCHAR(2), -- Caracter que se extraer� de cada nombre
    @nombre1 VARCHAR(20), -- Primer nombre de entrada
    @nombre2 VARCHAR(20), -- Segundo nombre de entrada
    @sql NVARCHAR(4000), -- Consulta din�mica que se construye
    @columna VARCHAR(5), -- Columna de la tabla a comparar
    @valor INT, -- Valor calculado en la comparaci�n
    @ParmDefinition NVARCHAR(50) -- Par�metros de la ejecuci�n din�mica
BEGIN
    -- Asignamos valores a las variables
    SET @nombre1 = 'martha'; -- Nombre 1
    SET @nombre2 = 'marta'; -- Nombre 2

    -- Creamos din�micamente la tabla para almacenar comparaciones
    SELECT @longitud = LEN(@nombre1);
    SELECT @contador = 1;
    SET @sql = '';

    -- Generamos las columnas din�micas basadas en los caracteres de los nombres
    WHILE @contador <= @longitud
    BEGIN
        SELECT @caracter = LEFT(@nombre1, 1);
        SELECT @nombre1 = RIGHT(@nombre1, LEN(@nombre1) - 1);
        SELECT @sql = @sql + @caracter + CAST(@contador AS VARCHAR(1)) + ' INT,';
        SELECT @contador = @contador + 1;
    END

    -- Creamos la tabla con las columnas din�micas generadas
    SET @sql = 'CREATE TABLE nombre (' + LEFT(@sql, LEN(@sql) - 1) + ')';
    EXECUTE sp_executesql @sql;

    -- Insertamos valores de la segunda cadena comparativa en la tabla
    SET @longitud = LEN(@nombre2);
    SELECT @contador = 1;
    WHILE @contador <= @longitud
    BEGIN
        SELECT @caracter = LEFT(@nombre2, 1);
        SELECT @nombre2 = RIGHT(@nombre2, LEN(@nombre2) - 1);
        
        -- Seleccionamos la columna correspondiente para insertar el valor
        SELECT TOP 1 @columna = COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'nombre'
        AND LEFT(COLUMN_NAME, 1) = @caracter 
        AND ORDINAL_POSITION >= @contador
        ORDER BY ORDINAL_POSITION;

        -- Inserci�n en la tabla para cada comparaci�n
        SET @sql = 'INSERT INTO nombre(' + @columna + ') VALUES (1)';
        EXECUTE sp_executesql @sql;
        SELECT @contador = @contador + 1;
    END

    -- Construimos una consulta din�mica para realizar la comparaci�n
    SET @sql = '';
    SELECT @contador = 1;
    SELECT @longitud = COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'nombre';

    -- Calculamos la comparaci�n de todos los valores sumados
    WHILE @contador <= @longitud
    BEGIN
        SELECT @columna = COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'nombre'
        AND ORDINAL_POSITION = @contador;
        SELECT @contador = @contador + 1;
        SET @sql = @sql + 'ISNULL(SUM(' + @columna + '), 0) + ';
    END

    -- Ejecutamos la consulta para calcular el valor comparativo final
    SET @sql = 'SELECT @valordevuelto = ' + LEFT(@sql, LEN(@sql) - 1) + ' FROM nombre';
    SET @ParmDefinition = N'@valordevuelto INT OUTPUT';
    EXECUTE sp_executesql @sql, @ParmDefinition, @valordevuelto = @valor OUTPUT;

    -- Mostramos el resultado de la comparaci�n
    PRINT @valor;
END

-- Mostramos la tabla 'nombre' con los resultados de las comparaciones
SELECT * FROM nombre;

-- Eliminamos la tabla 'nombre' despu�s de la comparaci�n
DROP TABLE nombre;
