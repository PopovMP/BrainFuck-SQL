-- Brain Fuck interpreter in SQL

DECLARE @Code  VARCHAR(MAX) = ', [>,] < [.<]'
DECLARE @Input VARCHAR(MAX) = '!dlroW olleH';

-- Creates a "BrainFuck" DataBase.
-- CREATE DATABASE BrainFuck;

-- Creates the Source code table
DECLARE @CodeTable TABLE (
    [Id]      INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    [Command] CHAR(1) NOT NULL
);

-- Populate the source code into CodeTable
DECLARE @CodeLen INT = LEN(@Code);
DECLARE @CodePos INT = 0;
DECLARE @CodeChar CHAR(1);

WHILE @CodePos < @CodeLen
BEGIN
    SET @CodePos  = @CodePos + 1;
    SET @CodeChar = SUBSTRING(@Code, @CodePos, 1);
    IF @CodeChar IN ('+', '-', '>', '<', ',', '.', '[', ']')
        INSERT INTO @CodeTable ([Command]) VALUES (@CodeChar)
END

-- Creates the Input table
DECLARE @InputTable TABLE (
    [Id]   INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    [Char] CHAR(1) NOT NULL
);

-- Populate the input text into InputTable
DECLARE @InputLen INT = LEN(@Input);
DECLARE @InputPos INT = 0;

WHILE @InputPos < @InputLen
BEGIN
    SET @InputPos = @InputPos + 1;
    INSERT INTO @InputTable ([Char])
    VALUES (SUBSTRING(@Input, @InputPos, 1))
END

-- Creates the Output table
DECLARE @OutputTable TABLE (
    [Id]   INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    [Char] CHAR(1) NOT NULL
);

-- Creates the Buffer table
DECLARE @BufferTable TABLE (
    [Id]     INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    [Memory] INT DEFAULT 0  NOT NULL
);
INSERT INTO @BufferTable ([Memory])
VALUES (0);

DECLARE @CodeLength INT = (SELECT COUNT(*) FROM @CodeTable);
DECLARE @CodeIndex  INT = 0;
DECLARE @Pointer    INT = 1;
DECLARE @InputIndex INT = 0;
DECLARE @Command    CHAR(1);
DECLARE @Depth      INT; 

WHILE @CodeIndex < @CodeLength
BEGIN
    -- Read the next command.
    SET @CodeIndex = @CodeIndex + 1;
    SET @Command = (SELECT [Command] FROM @CodeTable WHERE [Id] = @CodeIndex);

    -- Increment the pointer.
    IF @Command = '>'
    BEGIN
        SET @Pointer = @Pointer + 1;
        IF (SELECT [Id] FROM @BufferTable WHERE [Id] = @Pointer) IS NULL
            INSERT INTO @BufferTable ([Memory]) VALUES (0);
    END

    -- Decrement the pointer.    
    ELSE IF @Command = '<'
        SET @Pointer = @Pointer - 1;

    -- Increment the byte at the pointer.
    ELSE IF @Command = '+'
        UPDATE @BufferTable SET [Memory] = [Memory] + 1 WHERE [Id] = @Pointer;

    -- Decrement the byte at the pointer.
    ELSE IF @Command = '-'
        UPDATE @BufferTable SET [Memory] = [Memory] - 1 WHERE [Id] = @Pointer;

    -- Output the byte at the pointer.
    ELSE IF @Command = '.'
        INSERT INTO @OutputTable ([Char]) (SELECT CHAR([Memory]) FROM @BufferTable WHERE [Id] = @Pointer);

    -- Input a byte and store it in the byte at the pointer.
    ELSE IF @Command = ','
    BEGIN
        SET @InputIndex = @InputIndex + 1;
        UPDATE @BufferTable SET [Memory] = COALESCE((SELECT ASCII([Char]) FROM @InputTable WHERE [Id] = @InputIndex), 0) WHERE [Id] = @Pointer;
    END

    -- Jump forward past the matching ] if the byte at the pointer is zero.
    ELSE IF @Command = '[' AND COALESCE((SELECT [Memory] FROM @BufferTable WHERE [Id] = @Pointer), 0) = 0
    BEGIN
        SET @Depth = 1;
        WHILE @Depth > 0
        BEGIN
            SET @CodeIndex = @CodeIndex + 1;
            SET @Command = (SELECT [Command] FROM @CodeTable WHERE [Id] = @CodeIndex);
            IF @Command = '[' SET @Depth = @Depth + 1;
            ELSE IF @Command = ']' SET @Depth = @Depth - 1;
        END
    END

    -- Jump backward to the matching [ unless the byte at the pointer is zero.
    ELSE IF @Command = ']' AND COALESCE((SELECT [Memory] FROM @BufferTable WHERE [Id] = @Pointer), 0) != 0
    BEGIN
        SET @Depth = 1;
        WHILE @Depth > 0
        BEGIN
            SET @CodeIndex = @CodeIndex - 1;
            SET @Command = (SELECT [Command] FROM @CodeTable WHERE [Id] = @CodeIndex);
            IF @Command = ']' SET @Depth = @Depth + 1;
            ELSE IF @Command = '[' SET @Depth = @Depth - 1;
        END
    END
END;

DECLARE @Output VARCHAR(MAX);
SELECT @Output = COALESCE(@Output, '') + [Char] 
FROM @OutputTable;

PRINT @Output;
Go
