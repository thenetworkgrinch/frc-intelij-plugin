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

import org.wpilib.hardware.pneumatic.DoubleSolenoid.Value.FORWARD
import org.wpilib.hardware.pneumatic.DoubleSolenoid.Value.REVERSE

import org.wpilib.command3.Command
import org.wpilib.command3.Mechanism
import [=data.basePackage].Constants.HatchConstants
import org.wpilib.hardware.bus.CANPort
import org.wpilib.hardware.pneumatic.DoubleSolenoid
import org.wpilib.hardware.pneumatic.PneumaticsModuleType
import org.wpilib.telemetry.TelemetryLoggable
import org.wpilib.telemetry.TelemetryTable

/** A hatch mechanism actuated by a single [org.wpilib.hardware.pneumatic.DoubleSolenoid]. */
class HatchMechanism : Mechanism, TelemetryLoggable
{
    private val hatchSolenoid = DoubleSolenoid(
        CANPort.CAN_S0,
        PneumaticsModuleType.CTRE_PCM,
        HatchConstants.HATCH_SOLENOID_PORTS[0],
        HatchConstants.HATCH_SOLENOID_PORTS[1])

    /** Grabs the hatch. */
    fun grabHatchCommand(): Command
    {
        // implicitly require `this`
        return this.run { _ -> hatchSolenoid.set(FORWARD) }.named("Grab Hatch")
    }

    /** Releases the hatch. */
    fun releaseHatchCommand(): Command
    {
        // implicitly require `this`
        return this.run { _ -> hatchSolenoid.set(REVERSE) }.named("Release Hatch")
    }

    override fun logTo(table: TelemetryTable)
    {
        table.log("extended", hatchSolenoid.get() == FORWARD)
    }
}
