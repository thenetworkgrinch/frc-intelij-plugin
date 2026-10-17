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
package [=data.basePackage].subsystems

import org.wpilib.epilogue.Logged
import org.wpilib.command2.Command
import org.wpilib.command2.SubsystemBase
import org.wpilib.hardware.bus.CANPort
import org.wpilib.hardware.pneumatic.Compressor
import org.wpilib.hardware.pneumatic.PneumaticsModuleType
import org.wpilib.hardware.rotation.AnalogPotentiometer

/** Subsystem for managing the compressor, pressure sensor, etc. */
@Logged
class Pneumatics : SubsystemBase()
{
    companion object
    {
        // External analog pressure sensor
        // product-specific voltage->pressure conversion, see product manual
        // in this case, 250(V/5)-25
        // the scale parameter in the AnalogPotentiometer constructor is scaled from 1 instead of 5,
        // so if r is the raw AnalogPotentiometer output, the pressure is 250r-25
        const val SCALE = 250.0
        const val OFFSET = -25.0
    }

    private val pressureTransducer = AnalogPotentiometer(/* the AnalogIn port*/ 2, SCALE, OFFSET)

    // Compressor connected to a PCM with a default CAN ID (0)
    private val compressor = Compressor(CANPort.CAN_S0, PneumaticsModuleType.CTRE_PCM)

    /**
     * The measured pressure, in PSI, from the analog pressure sensor.
     */
    val pressure: Double
        // Get the pressure (in PSI) from an analog pressure sensor connected to the RIO.
        get() = pressureTransducer.get()

    /**
     * Disable the compressor closed-loop for as long as the command runs.
     *
     * Structured this way as the compressor is enabled by default.
     *
     * @return command
     */
    fun disableCompressorCommand(): Command =
        startEnd(
            // Disable closed-loop mode on the compressor.
            compressor::disable,
            // Enable closed-loop mode based on the digital pressure switch connected to the
            // PCM/PH.
            // The switch is open when the pressure is over ~120 PSI.
            compressor::enableDigital)
            .withName("Compressor Disabled")
}
