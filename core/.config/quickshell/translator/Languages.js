.pragma library

var languages = [
    { code: "AR", label: "Arabic" },
    { code: "BG", label: "Bulgarian" },
    { code: "ZH", label: "Chinese" },
    { code: "CS", label: "Czech" },
    { code: "DA", label: "Danish" },
    { code: "NL", label: "Dutch" },
    { code: "EN", label: "English" },
    { code: "ET", label: "Estonian" },
    { code: "FI", label: "Finnish" },
    { code: "FR", label: "French" },
    { code: "DE", label: "German" },
    { code: "EL", label: "Greek" },
    { code: "HU", label: "Hungarian" },
    { code: "ID", label: "Indonesian" },
    { code: "IT", label: "Italian" },
    { code: "JA", label: "Japanese" },
    { code: "KO", label: "Korean" },
    { code: "LV", label: "Latvian" },
    { code: "LT", label: "Lithuanian" },
    { code: "NB", label: "Norwegian" },
    { code: "PL", label: "Polish" },
    { code: "PT", label: "Portuguese" },
    { code: "RO", label: "Romanian" },
    { code: "RU", label: "Russian" },
    { code: "SK", label: "Slovak" },
    { code: "SL", label: "Slovenian" },
    { code: "ES", label: "Spanish" },
    { code: "SV", label: "Swedish" },
    { code: "TR", label: "Turkish" },
    { code: "UK", label: "Ukrainian" }
]

function sources() {
    return [{ code: "", label: "Auto-detect" }].concat(languages)
}

function targets() {
    const result = []
    for (const language of languages) {
        switch (language.code) {
        case "EN":
            result.push({ code: "EN-GB", label: "English (UK)" })
            result.push({ code: "EN-US", label: "English (US)" })
            break
        case "PT":
            result.push({ code: "PT-PT", label: "Portuguese (Portugal)" })
            result.push({ code: "PT-BR", label: "Portuguese (Brazil)" })
            break
        case "ZH":
            result.push({ code: "ZH-HANS", label: "Chinese (Simplified)" })
            result.push({ code: "ZH-HANT", label: "Chinese (Traditional)" })
            break
        default:
            result.push(language)
        }
    }
    return result
}

function targetFor(code) {
    return ({ EN: "EN-GB", PT: "PT-PT", ZH: "ZH-HANS" })[code] || code
}

function label(code) {
    const entry = sources().concat(targets()).find(language => language.code === code)
    return entry ? entry.label : code
}
