<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement,MainFunctionReturnUnit-->
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
package [=data.basePackage]

import org.junit.jupiter.api.Test

import org.junit.jupiter.api.Assertions.*

internal class ExampleTest
{
    // To learn more about how to write unit tests, see the
    // JUnit 5 User Guide at https://junit.org/junit5/docs/current/user-guide/

    @Test
    // In Kotlin, we can write test names with spaces by enclosing the names in backticks.
    // This lets us use names with clearer test purpose & intent.
    fun `string#lowerCase should handle mixed case and return all lower case`()
    {
        assertEquals("robot", "Robot".lowercase())
    }

    @Test
    fun `2 plus 2 should equal 4`()
    {
        assertEquals(4, 2 + 2)
    }
}

