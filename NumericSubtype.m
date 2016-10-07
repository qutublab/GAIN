classdef NumericSubtype
    enumeration
        POSITIVE,
        POSITIVE_INTEGER,
        POSITIVE_LE1
        NONNEGATIVE_INTEGER,
    end
  
    methods
        function isInt = isIntegerType(nst)
            switch nst
                case NumericSubtype.POSITIVE
                    isInt = false;
                case NumericSubtype.POSITIVE_INTEGER
                    isInt = true;
                case NumericSubtype.POSITIVE_LE1
                    isInt = false;
                case NumericSubtype.NONNEGATIVE_INTEGER
                    isInt = false;
                otherwise
                    error('[NumericSubtype.isIntegerType] Unexpected value: ', char(nst));
            end
        end
        
        function status = check(nst, num)
            status = '';
            if ~isnumeric(num) | ~isreal(num) | isnan(num)
                status = 'Value is not a real number';
                return;
            end
            if numel(num) ~= 1
                status = 'Value is not a single number';
                return;
            end
            switch nst
                case NumericSubtype.POSITIVE
                    if ~(num > 0)
                        status = 'Value is not a positive number';
                    end
                case NumericSubtype.POSITIVE_INTEGER
                    if ~((num - floor(num) == 0) && num > 0)
                        status = 'Value is not a positive integer';
                    end
                case NumericSubtype.POSITIVE_LE1
                    if ~(num > 0 && num <= 1)
                        status = 'Value is not positive and less than or equal to 1';
                    end
                case NumericSubtype.NONNEGATIVE_INTEGER
                    if ~((num - floor(num) == 0) && num >= 0)
                        status = 'Value is not a non-negative integer';
                    end
                otherwise
                    error('[NumericSubtype.check] Unexpected subtype:,%s', char(nst));

            end
        end

        function n2 = rectify(nst, n)
	    if ~isnumeric(n)
                error('[NumericSubtype.rectify] Argument is not numeric');
            end
            if ~isreal(n)
                error('[NumericSubtype.rectify] Argument is not a real number');
            end
            if isnan(n)
                error('[NumericSubtype.rectify] Argument is not a number');
            end

            if numel(n) ~= 1
                error('[NumericSubtype.rectify] Argument is not a singleton (%d)', numel(n));
            end

            switch nst
                case NumericSubtype.POSITIVE
                    n2 = max(n, realmin);
                case NumericSubtype.POSITIVE_INTEGER
                    n2 = max(1, round(n));
                case NumericSubtype.POSITIVE_LE1
                    n2 = min(1, max(n, realmin));
                case NumericSubtype.NONNEGATIVE_INTEGER
                    n2 = max(0, round(n));
                otherwise
                    error('[NumericSubtype.rectify] Unexpected subtype:,%s', char(nst));

            end

        end
    end


end
