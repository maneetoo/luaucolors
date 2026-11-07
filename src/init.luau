--!strict
--!native
--!optimize 2
--!nolint SameLineStatement
--upstream: https://github.com/tinylibs/tinyrainbow/blob/master/src/index.ts
--original: https://github.com/alexeyraspopov/picocolors/blob/main/picocolors.js

--NOTE: The JS built-ins used by tinyrainbow (`Number.parseInt`, `Object.assign`, `String` and its prototype methods) come from
--Lib-JS (`maneetoo/libjs`), so every string index and length below is counted in code points and is 0-based, as in JavaScript.
--repository: https://github.com/maneetoo/lib-js
const Number = require './Number'
const Object = require './Object'
const String = require './String'

--NOTE: Luau does not have `interface` as a distinct type like TS does—only `type`—so we use and export `type` instead of an interface.
export type Formatter = setmetatable<{
	open: string,
	close: string,
}, {
	__call: (self: Formatter, text: unknown) -> string,
}>

export type Colors = {
	read isColorSupported: boolean,

	read reset: Formatter,
	read bold: Formatter,
	read dim: Formatter,
	read italic: Formatter,
	read underline: Formatter,
	read inverse: Formatter,
	read hidden: Formatter,
	read strikethrough: Formatter,

	read black: Formatter,
	read red: Formatter,
	read green: Formatter,
	read yellow: Formatter,
	read blue: Formatter,
	read magenta: Formatter,
	read cyan: Formatter,
	read white: Formatter,
	read gray: Formatter,

	read bgBlack: Formatter,
	read bgRed: Formatter,
	read bgGreen: Formatter,
	read bgYellow: Formatter,
	read bgBlue: Formatter,
	read bgMagenta: Formatter,
	read bgCyan: Formatter,
	read bgWhite: Formatter,

	read blackBright: Formatter,
	read redBright: Formatter,
	read greenBright: Formatter,
	read yellowBright: Formatter,
	read blueBright: Formatter,
	read magentaBright: Formatter,
	read cyanBright: Formatter,
	read whiteBright: Formatter,

	read bgBlackBright: Formatter,
	read bgRedBright: Formatter,
	read bgGreenBright: Formatter,
	read bgYellowBright: Formatter,
	read bgBlueBright: Formatter,
	read bgMagentaBright: Formatter,
	read bgCyanBright: Formatter,
	read bgWhiteBright: Formatter,

	read rgb: (r: number, g: number, b: number) -> Formatter,
	read bgRgb: (r: number, g: number, b: number) -> Formatter,
	read hex: (hex: string) -> Formatter,
	read bgHex: (hex: string) -> Formatter,
}

--NOTE: Every formatter is a callable table: `colors.red("text")` is `colors.red.open .. "text" .. colors.red.close`, with the
--nested-close handling applied. Luau cannot type a callable table, so `__call` is declared on the metatable.
const noop: Formatter = setmetatable({
	open = "",
	close = "",
}, {
	__call = function(_self: Formatter, text: unknown): string
		return String(text)
	end,
}) :: Formatter

const noopFormatter = function(): Formatter
	return noop
end

const fgClose = "\x1B[39m"
const bgClose = "\x1B[49m"

--NOTE: `result += string.substring(cursor, index) + replace` in the original. Every `indexOf` here is the Lib-JS one, so
--`-1` means "not found", as in JavaScript.
const replaceClose = function(str: string, close: string, replace: string, index: number, closeLength: number): string
	local result = ""
	local cursor = 0
	repeat
		result ..= String.prototype.substring(str, cursor, index) .. replace
		cursor = index + closeLength
		index = String.prototype.indexOf(str, close, cursor)
	until index == -1
	return result .. String.prototype.substring(str, cursor)
end

const makeFormatter = function(open: string, close: string, replace: string?, offset: number?): Formatter
	const replacement = replace or open
	const searchFrom = offset or String.prototype.length(open)
	const closeLength = String.prototype.length(close)
	const formatter = setmetatable({
		open = open,
		close = close,
	}, {
		__call = function(_self: Formatter, input: unknown): string
			const str = String(input)
			const index = String.prototype.indexOf(str, close, searchFrom)
			if index ~= -1 then
				return open .. replaceClose(str, close, replacement, index, closeLength) .. close
			end
			return open .. str .. close
		end,
	})
	return formatter :: Formatter
end

const trueColor = function(open: string, close: string): Formatter
	return makeFormatter(open, close, open, 5)
end

--NOTE: Accepts `"#rrggbb"`, `"rrggbb"`, `"#rgb"` and `"rgb"`. Invalid input becomes `0`, as `parseInt(...) || 0` does in JS.
const hexToRgb = function(hex: string): string
	const digits = if String.prototype.charCodeAt(hex, 0) == 35 then String.prototype.slice(hex, 1) else hex
	local value = Number.parseInt(digits, 16)
	--NOTE: `NaN` is the only value that is not equal to itself.
	if value ~= value then
		value = 0
	end
	if String.prototype.length(digits) < 6 then
		return string.format("%d;%d;%d",
			bit32.band(bit32.rshift(value, 8), 15) * 17,
			bit32.band(bit32.rshift(value, 4), 15) * 17,
			bit32.band(value, 15) * 17)
	end
	return string.format("%d;%d;%d",
		bit32.band(bit32.rshift(value, 16), 255),
		bit32.band(bit32.rshift(value, 8), 255),
		bit32.band(value, 255))
end

--NOTE: The map is returned as a plain table and is not frozen. `disableDefaultColors` and `enabledDefaultColors` write into
--the default instance with `Object.assign`, which a frozen table would reject.
const createColorsMap = function(enabled: boolean): Colors
	const f = if enabled then makeFormatter else noopFormatter
	const colorMap = {
		isColorSupported = enabled,
		reset = f("\x1B[0m", "\x1B[0m"),
		bold = f("\x1B[1m", "\x1B[22m", "\x1B[22m\x1B[1m"),
		dim = f("\x1B[2m", "\x1B[22m", "\x1B[22m\x1B[2m"),
		italic = f("\x1B[3m", "\x1B[23m"),
		underline = f("\x1B[4m", "\x1B[24m"),
		inverse = f("\x1B[7m", "\x1B[27m"),
		hidden = f("\x1B[8m", "\x1B[28m"),
		strikethrough = f("\x1B[9m", "\x1B[29m"),

		black = f("\x1B[30m", fgClose),
		red = f("\x1B[31m", fgClose),
		green = f("\x1B[32m", fgClose),
		yellow = f("\x1B[33m", fgClose),
		blue = f("\x1B[34m", fgClose),
		magenta = f("\x1B[35m", fgClose),
		cyan = f("\x1B[36m", fgClose),
		white = f("\x1B[37m", fgClose),
		gray = f("\x1B[90m", fgClose),

		bgBlack = f("\x1B[40m", bgClose),
		bgRed = f("\x1B[41m", bgClose),
		bgGreen = f("\x1B[42m", bgClose),
		bgYellow = f("\x1B[43m", bgClose),
		bgBlue = f("\x1B[44m", bgClose),
		bgMagenta = f("\x1B[45m", bgClose),
		bgCyan = f("\x1B[46m", bgClose),
		bgWhite = f("\x1B[47m", bgClose),

		blackBright = f("\x1B[90m", fgClose),
		redBright = f("\x1B[91m", fgClose),
		greenBright = f("\x1B[92m", fgClose),
		yellowBright = f("\x1B[93m", fgClose),
		blueBright = f("\x1B[94m", fgClose),
		magentaBright = f("\x1B[95m", fgClose),
		cyanBright = f("\x1B[96m", fgClose),
		whiteBright = f("\x1B[97m", fgClose),

		bgBlackBright = f("\x1B[100m", bgClose),
		bgRedBright = f("\x1B[101m", bgClose),
		bgGreenBright = f("\x1B[102m", bgClose),
		bgYellowBright = f("\x1B[103m", bgClose),
		bgBlueBright = f("\x1B[104m", bgClose),
		bgMagentaBright = f("\x1B[105m", bgClose),
		bgCyanBright = f("\x1B[106m", bgClose),
		bgWhiteBright = f("\x1B[107m", bgClose),

		rgb = function(r: number, g: number, b: number): Formatter
			return if enabled then trueColor(string.format("\x1B[38;2;%d;%d;%dm", r, g, b), fgClose) else noop
		end,
		bgRgb = function(r: number, g: number, b: number): Formatter
			return if enabled then trueColor(string.format("\x1B[48;2;%d;%d;%dm", r, g, b), bgClose) else noop
		end,
		hex = function(hex: string): Formatter
			return if enabled then trueColor("\x1B[38;2;" .. hexToRgb(hex) .. "m", fgClose) else noop
		end,
		bgHex = function(hex: string): Formatter
			return if enabled then trueColor("\x1B[48;2;" .. hexToRgb(hex) .. "m", bgClose) else noop
		end,
	}
	return colorMap :: Colors
end

--NOTE: Luau does not support `export const`; therefore, we use a table to hold all the enums and functions
--to be exported, and return that table.
const luaucolors = {}

--NOTE: `process` does not exist in Luau, and the standard `os` library has no `getenv` on Roblox or in the plain CLI. Hosts
--that do provide `os.getenv` (for example Lune) are detected at call time. Everywhere else the environment reads as empty.
const canReadEnv = function(): boolean
	const osLib: any = os
	return type(osLib) == "table" and type(osLib.getenv) == "function"
end

const getEnv = function(name: string): string?
	const osLib: any = os
	return osLib.getenv(name)
end

--NOTE: `isSupported` was empty in the draft; the body below mirrors the upstream checks, in the same order.
--NOTE: The upstream `--no-color` / `--color` flags are not checked: Luau has no `process.argv`.
--NOTE: The upstream browser branch (`window.chrome`) is not ported: Luau has no `window`. Without a readable environment
--the result is `false`, which is also what upstream returns when `process` is undefined in a non-browser context.
const function isSupported(): boolean
	if not canReadEnv() then
		return false
	end
	if getEnv("NO_COLOR") ~= nil then
		return false
	end
	if getEnv("FORCE_COLOR") ~= nil or getEnv("CI") ~= nil or getEnv("OS") == "Windows_NT" then
		return true
	end
	--NOTE: Upstream comment: `// assume TTY`. Luau cannot ask whether stdout is a terminal, so `isTTY` is `true` unless
	--`FORCE_TTY` is exactly `"false"`.
	const isTTY = getEnv("FORCE_TTY") ~= "false"
	return isTTY and getEnv("TERM") ~= "dumb"
end luaucolors.isSupported = isSupported

const function createColors(options: { force: boolean? }?): Colors
	const force = if options ~= nil then options.force else nil
	const enabled = force == true or isSupported()
	return createColorsMap(enabled)
end luaucolors.createColors = createColors

const function getDefaultColors(): Colors
	return createColorsMap(false)
end luaucolors.getDefaultColors = getDefaultColors

const colors = createColors()

const function disableDefaultColors()
	Object.assign(colors :: any, getDefaultColors() :: any)
end luaucolors.disableDefaultColors = disableDefaultColors

const function enabledDefaultColors()
	Object.assign(colors :: any, createColorsMap(true) :: any)
end luaucolors.enabledDefaultColors = enabledDefaultColors

return setmetatable(colors, {
	__index = luaucolors
})
