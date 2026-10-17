<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This template uses alternate square bracket interpolation syntax
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
package [=data.basePackage].mechanisms

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import org.wpilib.command3.Trigger

/** An example class demonstrating basic use of mechanisms and commands. */
class ExampleMechanism : Mechanism
{
    val exampleCondition = Trigger { false }

    /**
     * An example command that requires this mechanism. Only one command that requires this mechanism
     * may run at a time - if a command is already running, this command will interrupt it.
     *
     * This example runs indefinitely and prints a message every time it executes.
     *
     * @return An example command.
     */
    fun exampleCommand(): Command =
        run { coroutine ->
            var runCount = 0
            while (true)
            {
                runCount++
                println("Example command run #$runCount")
                coroutine.yield()
            }
        }.named("Example Command")
}
