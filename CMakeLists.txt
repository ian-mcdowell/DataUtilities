
set(sources
    "Async.swift"
    "BonjourBrowser.swift"
    "Errno.swift"
    "Errors.swift"
    "ExtensionLoader.swift"
    "LinkHeader.swift"
    "OrderedDictionary.swift"
    "Platform.swift"
    "Result.swift"
    "Extension/AnyObject+Custom.swift"
    "Extension/Array+Custom.swift"
    "Extension/Date+Custom.swift"
    "Extension/Dictionary+Custom.swift"
    "Extension/NSDateFormatter+Custom.swift"
    "Extension/NSError+Custom.swift"
    "Extension/String+Custom.swift"
    "Extension/URL+Custom.swift"
)

add_framework_target(
    DataUtilities
    BUNDLE_ID net.ianmcdowell.DataUtilities
    SOURCES "${sources}"
    PUBLIC_HEADERS ""
    APP_EXTENSION_API
)