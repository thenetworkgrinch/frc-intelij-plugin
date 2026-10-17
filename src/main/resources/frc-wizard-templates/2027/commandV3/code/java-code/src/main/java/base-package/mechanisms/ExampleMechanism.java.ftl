<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage}.mechanisms;

import org.wpilib.command3.Command;
import org.wpilib.command3.Mechanism;
import org.wpilib.command3.Trigger;

/** An example class demonstrating basic use of mechanisms and commands. */
public class ExampleMechanism implements Mechanism {
  public final Trigger exampleCondition = new Trigger(() -> false);

  /**
   * An example command that requires this mechanism. Only one command that requires this mechanism
   * may run at a time - if a command is already running, this command will interrupt it.
   *
   * <p>This example runs indefinitely and prints a message every time it executes.
   *
   * @return An example command.
   */
  public Command exampleCommand() {
    return run(coroutine -> {
          int runCount = 0;
          while (true) {
            runCount++;
            System.out.println("Example command run #" + runCount);
            coroutine.yield();
          }
        })
        .named("Example Command");
  }
}
