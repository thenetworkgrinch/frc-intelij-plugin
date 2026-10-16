<#ftl output_format="plainText" encoding="UTF-8"> <#-- Output formats: https://freemarker.apache.org/docs/dgui_misc_autoescaping.html -->
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This tempolate uses alternate square bracket interpolation syntax
               For example:
                    [=data.robotClassSimpleName]
               rather than:
                    ${data.robotClassSimpleName}
               so as to not clash with Kotlin string templates syntax
               The option to use that can't be set in the template, but has to be set as an
               option on the Configuration object in the code. Note that this only affects interpolation
               syntax, and *NOT* Tag syntax. So we will still use `<#if isSuchAndSuch>` and not `[#if isSuchAndSuch]`.
               Tag syntax can be changed if desired, but we are not.
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
pluginManagement {
    repositories {
        mavenLocal()
        gradlePluginPortal()
        val frcYear = "[=data.frcYearString]"
        val frcHome = if (System.getProperty("os.name").contains("windows", ignoreCase = true)) {
            file(System.getenv("PUBLIC") ?: """C:\Users\Public""")
        } else {
            file(System.getProperty("user.home"))
        }
            .resolve("wpilib")
            .resolve(frcYear)

        maven {
            name = "frcHome"
            url = uri(frcHome.resolve("maven"))
        }
    }
}

System.getProperties().apply {
    setProperty("org.gradle.internal.native.headers.unresolved.dependencies.ignore", "true")
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version ("0.9.0")
}