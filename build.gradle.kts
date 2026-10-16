/*
 * Copyright 2015-2022 the original author or authors.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *       https://www.apache.org/licenses/LICENSE-2.0
 *     
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */

import org.gradle.api.tasks.testing.logging.TestExceptionFormat
import org.jetbrains.gradle.ext.ProjectSettings
import org.jetbrains.kotlin.gradle.plugin.getKotlinPluginVersion
import java.io.FileNotFoundException
import java.io.PrintWriter
import java.nio.file.Files
import java.nio.file.Path
import java.util.*


val frcPluginBaseVersion: String = project.property("frcPluginBaseVersion").toString()
val ideaMajorVersion: String = project.property("ideaMajorVersion").toString()
val ideaVersionPlain: String = project.property("ideaVersionPlain").toString()
val ideaSinceBuild: String = project.property("ideaSinceBuild").toString()
val ideaUntilBuild: String = project.property("ideaUntilBuild").toString()
val frcPluginEapDesignator: String = project.property("frcPluginEapDesignator").toString()
val frcPluginVersion = "$frcPluginBaseVersion-$ideaMajorVersion$frcPluginEapDesignator" // ex: v1.3.0-2019.2,  1.3.1-2020.1-eap.1
val javaVersion: JavaVersion = JavaVersion.VERSION_25 // IJ v2026.2+ requires Java 25; IJ v2024.2+ requires Java 21; IJ v2022.2+ requires Java 17; IJ v2020.3+ requires Java 11
val kotlinVersion = project.getKotlinPluginVersion()
val sandboxPath = determineSandboxDir()
val tokenReplacements by lazy { loadTokenReplacements() }
val isCiBuild = project.findProperty("is.ci.build")?.toString()?.toBoolean() ?: false
val userHomeDir: Path by lazy { Path.of(System.getProperty("user.home")) }

group = "net.javaru.iip.frc"
version = frcPluginVersion 

plugins {
    base
    java
    // List of Kotlin versions bundled with the IDE by version:
    // https://plugins.jetbrains.com/docs/intellij/using-kotlin.html#stdlib-miscellaneous
    kotlin("jvm") version "2.4.0"
    // IntelliJ Platform Gradle Plugin: gradle plugin-for writing IntelliJ plugins
    //     Docs: https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin.html
    //           Last version of docs on GitHub before migration: https://github.com/JetBrains/gradle-intellij-plugin/blob/e819958cdc4e593738cd96e230edd5ca66481b3b/README.md
    //     Info: https://lp.jetbrains.com/gradle-intellij-plugin/
    //     Src:  https://github.com/JetBrains/gradle-intellij-plugin
    id("org.jetbrains.intellij.platform") version "2.19.0"


    // Extends the Gradle's "idea" DSL with specific settings: code style, facets, run configurations etc.
    //    https://github.com/jetbrains/gradle-idea-ext-plugin
    //    https://plugins.gradle.org/plugin/org.jetbrains.gradle.plugin.idea-ext
    //    v0.10+ requires IDEA 2020.2+   v0.6.1+ requires IntelliJ IDEA 2019.2
    id("org.jetbrains.gradle.plugin.idea-ext") version "0.10"
    // https://docs.spring.io/dependency-management-plugin/docs/current/reference/html/
    id("io.spring.dependency-management") version "1.1.7"
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(javaVersion.toString()))
        // Temporarily disabling use of JBR due to build exceptions: org.gradle.internal.resolve.ModuleVersionResolveException: Could not resolve com.jetbrains:jbre:jbr_jcef-17.0.4.1-windows-x64-b653.1
        //vendor.set(determineJvmVendor(defaultFallbackSpec = JvmVendorSpec.ADOPTOPENJDK))
        vendor.set(JvmVendorSpec.ADOPTIUM)
    }
}

intellijPlatform {
    
    pluginConfiguration {
        ideaVersion {
            sinceBuild = ideaSinceBuild
            untilBuild = ideaUntilBuild
        }    
        
//        vendor { 
//            name = "Mark Vedder"
//            url = "https://gitlab.com/Javaru/frc-intellij-idea-plugin"
//        }
    }
    
    
    
    sandboxContainer.set(File(sandboxPath))
    
    pluginVerification {
        // https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin-extension.html#intellijPlatform-pluginVerification
        // TODO - configure pluginVerification
        ides {
            // Locally installed IDEs to verify against, such as CLion. ex: -PverifierLocalIdePaths=C:/Users/me/AppData/Local/Programs/CLion
            projectPropertyList("verifierLocalIdePaths").filter { it.isNotBlank() }.forEach { local(file(it.replace("~", System.getProperty("user.home")))) }
        }
    }
    
    // TODO:
    //    Downloading sources is managed by the Plugin DevKit plugin in version 2024.1+. Not finding that setting https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin-migration.html#intellijdownloadsources
}


// Runs CLion (for C++ robot projects) with the plugin. CLion does not bundle the Gradle plugin, so it is installed from the Marketplace.
//    Uses a locally installed CLion if 'clionLocalPath' is set (ex: -PclionLocalPath=C:/Users/me/AppData/Local/Programs/CLion), otherwise downloads CLion 'ideaVersionPlain'
intellijPlatformTesting {
    runIde {
        register("runClion") {
            val clionLocalPath = projectProperty("clionLocalPath", "")
            if (clionLocalPath.isNotBlank()) {
                localPath.set(file(clionLocalPath.replace("~", System.getProperty("user.home"))))
            } else {
                type.set(org.jetbrains.intellij.platform.gradle.IntelliJPlatformType.CLion)
                version.set(ideaVersionPlain)
            }
            plugins {
                plugin("com.intellij.gradle", projectProperty("clionGradlePluginVersion", "262.10968.211"))
            }
            // Opens a (trusted) project on startup. ex: -PrunClionProject=C:/robots/MyCppRobot
            val runClionProject = projectProperty("runClionProject", "")
            if (runClionProject.isNotBlank()) {
                task {
                    args(runClionProject)
                    jvmArgs("-Didea.trust.all.projects=true")
                }
            }
        }
    }
}

// Section to configure tasks specific to intellij plugin tasks
tasks {
    patchPluginXml {
//        version.set(frcPluginVersion)
        sinceBuild.setViaProjectProperty("ideaSinceBuild")
        untilBuild.setViaProjectProperty("ideaUntilBuild")
        val ppxTask = this
        doLast {
            fun Any?.isNotSet(): Boolean = (this == null || this.toString().contains("example.com/stand-in/value"))
            if (tokenReplacements["SENTRY_DSN_TEST_AND_QA"].isNotSet() || tokenReplacements["SENTRY_DSN_PROD"].isNotSet())
            {
                fun String.willRun(): Boolean = (gradle.taskGraph.hasTask(":$this") || gradle.taskGraph.hasTask(":${project.name}:$this") || gradle.taskGraph.hasTask(this))
                if (!isCiBuild && ("signPlugin".willRun() || "publishPlugin".willRun() 
                    || (("buildPlugin".willRun() && !(frcPluginVersion.contains("SNAPSHOT") || frcPluginVersion.contains("-UNOFFICIAL"))))))
                {
                    val message = "ErrorSubmitter DSN is not configured for build. This must be set when building the plugin for a release. If this is a non-release build, set the 'frcPluginEapDesignator' property to '-SNAPSHOT' in the gradle.properties file. If it is a personal build, set set the 'frcPluginEapDesignator' property to '-UNOFFICIAL' in the gradle.properties file."
                    logger.error(message)
                    error(message)
                }
                
                logger.warn("WARNING: ErrorSubmitter DSN is not configured for build. Error reports from this build will not be submitted.")
                // TODO: Determine how to do this in the v2.x plugin
//                logger.warn("WARNING: ErrorSubmitter DSN is not configured for build. Commenting out <errorHandler .../> entry in plugin.xml file.")
//                val dir = ppxTask.destinationDir.get()
//                val originalFile = dir.file("plugin.xml").asFile
//                val filteredFile = dir.file("plugin-FILTERED.xml").asFile
//                filteredFile.printWriter().use { pw: PrintWriter ->
//                    originalFile.readLines().forEach {
//                        val line = if (it.contains("<errorHandler")) "<!-- $it -->" else it
//                        pw.println(line)
//                    }
//                }
//                filteredFile.copyTo(originalFile, overwrite = true)
//                filteredFile.delete()
            }
        }
    }

    runIde {
        jvmArgs = listOf("-Xms512m", "-Xmx1g")
        // The IDE's classpath is too long for the Windows command line, so Gradle falls back to a "pathing jar" whose manifest
        // holds the Class-Path. The IDE's system class loader (com.intellij.util.lang.PathClassLoader) reads java.class.path
        // directly and ignores manifest Class-Path entries, so the IDE fails with "ClassNotFoundException: com.intellij.idea.Main"
        // (or for the coroutines debug agent). Passing the classpath via a Java @argfile avoids the pathing jar.
        doFirst {
            val cpArgFile = temporaryDir.resolve("classpath.argfile")
            // Forward slashes, since backslashes are escape characters in quoted argfile values
            cpArgFile.writeText("-cp \"" + classpath.files.joinToString(File.pathSeparator) { it.absolutePath.replace('\\', '/') } + "\"")
            classpath = files()
            jvmArgs("@${cpArgFile.absolutePath}")
        }
        systemProperties = mapOf(
            //"key" to "value",
            //systemPropertyGetOrDefault("idea.log.config.file", resolvePath(project.rootDir.canonicalPath, ".sandbox", "log.xml")),
            // As of v2022.1, changed from using log4j to JUL
            //    See https://blog.jetbrains.com/platform/2022/02/removing-log4j-from-the-intellij-platform/
            //        https://docs.oracle.com/en/java/javase/11/docs/api/java.logging/java/util/logging/LogManager.html
            //systemPropertyGetOrDefault("idea.log.config.file", resolvePath(project.rootDir.canonicalPath, "idea-sandbox-log4j-config.xml")),
            systemPropertyGetOrDefault("idea.log.config.properties.file", resolvePathFromProjectRootAsString("idea-sandbox-logging.properties")),
            systemPropertyGetOrDefault("frc.show.betas.in.new.project.wizard", "true"),
            // Turn on frc.i10n to see a notification character appended to all localized messages to aid in testing/debugging of message bundles and localization needs
            systemPropertyGetOrDefault("frc.i10n", "false"),
            systemPropertyGetOrDefault("frc.is.internal", "true"),
            systemPropertyGetOrDefault("frc.rest.use.qa", "true"),
            systemPropertyGetOrDefault("frc.error.report.submitter.use.qa", "true"),
            //systemPropertyGetOrDefault("frc.experimental.gradleDslSelection", "true"),
            systemPropertyGetOrDefault("frc.wizard.always.update.wpilib.versions", "true"),
            systemPropertyGetOrDefault("frc.always.create.romi.tail.run.config", "false"),
            // Legacy Ant based robot project system properties
            //systemPropertyGetOrDefault("frc.simulated.log.service.enabled", "false"),
            //systemPropertyGetOrDefault("frc.simulated.log.service.use.configured.port", "false"),
            //systemPropertyGetOrDefault("frc.use.wpilib.beta.site", "false"),
            //systemPropertyGetOrDefault("frc.alt.wpilib.base.dir", ""),
            //systemPropertyGetOrDefault("wpilib.base.dir", "")
                                )
    }

//    runPluginVerifier {
//        // Reports appear in ${project.buildDir}/reports/pluginVerifier by default. Set `verificationReportsDirectory` to change
//        val baseDir = File(projectProperty("verifierLocalIdesBaseDir").replace("~", System.getProperty("user.home")))
//        localPaths.set(projectPropertyList("verifierLocalIdes").map { File(baseDir, it) })
//        ideVersions.set(projectPropertyList("verifierIdeVersions")) 
//    }

    signPlugin {
        // signPlugin runs automatically before the publishPlugin if the signPlugin privateKey (or privateKeyFile) and certificateChain (or certificateChainFile) properties are specified
        // Use JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_FILE unless overridden by the more specific FRC_PLUGIN_JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_FILE
        val ourCertChainFileSetting =
            System.getenv("FRC_PLUGIN_JETBRAINS_MARKETPLACE_SIGNING_CERTIFICATE_CHAIN_FILE") ?:
            System.getenv("JETBRAINS_MARKETPLACE_SIGNING_CERTIFICATE_CHAIN_FILE")
        val ourPrivateKeyFileSetting =
            System.getenv("FRC_PLUGIN_JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_FILE") ?:
            System.getenv("JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_FILE")

        doFirst {
            if (ourCertChainFileSetting == null) {
                logger.warn("No code signing certificate chain file configured.")
                logger.warn("environment variable 'JETBRAINS_MARKETPLACE_SIGNING_CERTIFICATE_CHAIN_FILE' not set.")
            }
            else {
                logger.lifecycle("Using code signing certificate chain file: $ourPrivateKeyFileSetting")
            }
            if (ourPrivateKeyFileSetting == null) {
                logger.warn("No code signing private key file configured.")
                logger.warn("environment variable 'JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_FILE' not set.")
            }
            else {
                logger.lifecycle("Using code signing private key file: $ourPrivateKeyFileSetting")
                if ((System.getenv("FRC_PLUGIN_JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_PASSWORD") ?: System.getenv("JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_PASSWORD")) == null) {
                    logger.warn("Code signing password is not configured.")
                    logger.warn("environment variable 'JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_PASSWORD' not set.")
                }
            }
        }
        if (ourPrivateKeyFileSetting != null && ourCertChainFileSetting != null)
        {
            privateKeyFile.set(Path.of(ourPrivateKeyFileSetting).toFile())
            certificateChainFile.set(Path.of(ourCertChainFileSetting).toFile())
            password.set(System.getenv("FRC_PLUGIN_JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_PASSWORD") ?: System.getenv("JETBRAINS_MARKETPLACE_SIGNING_PRIVATE_KEY_PASSWORD"))
        }
    }

    publishPlugin {
        // See https://plugins.jetbrains.com/docs/intellij/deployment.html  and  https://github.com/JetBrains/intellij-platform-plugin-template/blob/main/build.gradle.kts
        // dependsOn("patchChangelog")
        // For now, we will not use the `publish` task unless this project property is set. Once we have tested things, we can remove this guard
        onlyIf {
            projectPropertyBoolean("autoPublish", defaultValue = false)
        }

        project.version = "${project.version}" //-${properties["buildNumber"]}"

        // Use JETBRAINS_MARKETPLACE_PUBLISH_TOKEN unless overridden by the more specific FRC_PLUGIN_JETBRAINS_MARKETPLACE_PUBLISH_TOKEN
//        token.set(System.getenv("FRC_PLUGIN_JETBRAINS_MARKETPLACE_PUBLISH_TOKEN") ?: System.getenv("JETBRAINS_MARKETPLACE_PUBLISH_TOKEN"))
        token.set("TEMP_DUMMY_TOKEN")
        //
        // Specify pre-release label to publish the plugin in a custom Release Channel automatically. Read more:
        // https://plugins.jetbrains.com/docs/intellij/deployment.html#specifying-a-release-channel
        // example of setting programmatically, which assumes pluginVersion is based on the SemVer (https://semver.org) and supports pre-release labels, like 2.1.7-alpha.3
        //   channels.set(listOf(projectProperty("pluginVersion").split('-').getOrElse(1) { "default" }.split('.').first()))
        channels.set(listOf("default" ))
    }
}

tasks {
    withType<JavaCompile> {
        options.encoding = Charsets.UTF_8.name()
    }

    withType<Test> {
        useJUnitPlatform {
            excludeTags = setOf("slow", "manual")
        }
        systemProperty("file.encoding", Charsets.UTF_8.name())
        configureEach {
            testLogging {
                events("failed")
                exceptionFormat = TestExceptionFormat.FULL
            }
        }
    }

    withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        all {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(javaVersion.toString()))
                javaParameters.set(true)
                //noReflect = false
            }
        }
    }

    test {
        useJUnitPlatform {
            excludeTags("slow")
        }
    }

    clean {
        dependsOn("cleanPluginFromSandbox", "cleanIdeCaches")
    }

    processResources {
        filesMatching("services/frc-plugin-tokens.properties") {
            expand(tokenReplacements)
        }
    }

    register<Delete>("cleanPluginFromSandbox") {
        delete(
            File("$sandboxPath/IC-${ideaVersionPlain}/plugins/${rootProject.name}"),
            
              )
    }

    register<Delete>("cleanIdeCaches") {
        dependsOn("cleanPluginFromSandbox")
        // Delete indexes & cache to resolve issues of new project templates being read from cache
        delete(
            File("$sandboxPath/IC-${ideaVersionPlain}/system/caches"), 
            File("$sandboxPath/IC-${ideaVersionPlain}/system/index"),
            File("$sandboxPath/IU-${ideaVersionPlain}/system/caches"), 
            File("$sandboxPath/IU-${ideaVersionPlain}/system/index"),
              )
//    File("$sandboxPath/plugins/${rootProject.name}").deleteRecursively()
//    File("$sandboxPath/system/caches").deleteRecursively()
//    File("$sandboxPath/system/index").deleteRecursively()
    }
}

repositories {
    mavenCentral()
    flatDir { dirs("lib") }
    intellijPlatform {
        defaultRepositories()
    }
    maven {
        url = uri("https://oss.sonatype.org/content/repositories/snapshots/")
        mavenContent {
            snapshotsOnly()
        }
    }
}

@Suppress("SpellCheckingInspection")
dependencyManagement {
    imports {
        mavenBom("io.sentry:sentry-bom:6.4.3")
        mavenBom("com.google.guava:guava-bom:31.1-jre")
        mavenBom("com.fasterxml.jackson:jackson-bom:2.13.4")
        mavenBom("org.junit:junit-bom:5.9.1")
        mavenBom("org.jetbrains.kotlin:kotlin-bom:$kotlinVersion")
    }

    dependencies {
        dependency("io.javaru.iip.common:javaru-iip-common:1.0.0")
        dependency("org.jdom:jdom2:2.0.6.1")
        dependency("commons-io:commons-io:2.11.0")
        dependency("org.apache.commons:commons-lang3:3.12.0")
        dependency("org.apache.commons:commons-text:1.9")
        dependency("com.jcraft:jsch:0.1.55")
        dependency("com.beust:klaxon:5.6")
        dependency("org.freemarker:freemarker:2.3.31")
        dependency("io.github.furstenheim:copy_down:1.1") // HTML to MD
        dependency("org.jsoup:jsoup:1.15.1") // version pulled in by copy_down has a vulnerability; while unlikely to affect us, it's best to remove it.
        // jsemver: Is in the project 'lib' dir as it is not published to any public repos. Plus we are using a tweaked version that removes its use of logback
        dependency("com.asarkar:jsemver:0.6.2.3") {
            // We can't have SLF4J in our plugin's lib as it causes Classloader issues due the unique way it is loaded.
            exclude("org.slf4j:slf4j-api")
        }
        dependency("org.antlr:antlr4:4.9.3") {
            exclude("org.slf4j:slf4j-api")
        }

        dependencySet("com.michael-bull.kotlin-result:1.1.16") {
            entry("kotlin-result")
            entry("kotlin-result-jvm")
        }
    }
}

@Suppress("SpellCheckingInspection")
dependencies {
    intellijPlatform {
        intellijIdea(ideaVersionPlain)

        bundledPlugin("com.intellij.java")
        bundledPlugin("com.intellij.gradle")
        bundledPlugin("org.intellij.groovy")
        bundledPlugin("org.jetbrains.kotlin")
        bundledPlugin("com.jetbrains.sh")
        bundledPlugin("com.intellij.modules.json")

        pluginVerifier()
        zipSigner()

    }
    
    
    implementation("io.javaru.iip.common:javaru-iip-common")
    // For Kotlin dependencies, you can use shorthand for a dependency on a Kotlin module, for example, kotlin("test-junit5") for "org.jetbrains.kotlin:kotlin-test-junit5".
    implementation(kotlin("stdlib-jdk8"))
    implementation(kotlin("reflect"))
    testImplementation(kotlin("test-junit5"))

    implementation("org.jdom:jdom2")
    implementation("commons-io:commons-io")
    implementation("org.apache.commons:commons-lang3")
    implementation("org.apache.commons:commons-text")
    implementation("com.jcraft:jsch")
    // Klaxon is a library to parse JSON in Kotlin.  https://github.com/cbeust/klaxon  Help available in the #klaxon channel of the Kotlin Slack Workspace
    implementation("com.beust:klaxon")
    implementation("com.google.guava:guava")
    // jsemver: Is in the project 'lib' dir as it is not published to any public repos. Plus we are using a tweaked version that removes is use of logback
    implementation("com.asarkar:jsemver") {
        exclude(group = "org.slf4j", module = "slf4j-api")
            .because("We can't have SLF4J in our plugin's lib as it causes Classloader issues due the unique way it is loaded.")
    }
    implementation("org.antlr:antlr4") {
        exclude(group = "org.slf4j", module = "slf4j-api")
            .because("We can't have SLF4J in our plugin's lib as it causes Classloader issues due the unique way it is loaded.")
    }
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("com.fasterxml.jackson.datatype:jackson-datatype-guava")
    implementation("org.freemarker:freemarker")
    implementation("com.michael-bull.kotlin-result:kotlin-result")
    implementation("com.michael-bull.kotlin-result:kotlin-result-jvm")
    implementation("io.github.furstenheim:copy_down") // HTML to MD

    implementation("io.sentry:sentry") {
        exclude(group = "org.slf4j", module = "slf4j-api")
            .because("We can't have SLF4J in our plugin's lib as it causes Classloader issues due the unique way it is loaded.")
    }
    implementation("io.sentry:sentry-kotlin-extensions")

    testImplementation("org.junit.jupiter:junit-jupiter-api")
    testImplementation("org.junit.jupiter:junit-jupiter-params")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine")
    testRuntimeOnly("org.junit.vintage:junit-vintage-engine")
    testImplementation("com.google.guava:guava-testlib") // version in BOM above
}

idea {
    module {
        isDownloadJavadoc = true
        isDownloadSources = true
    }
    // Configure some IDEA Project settings (i.e. for Intellij IDEA used to code the plugin)
    // https://github.com/JetBrains/gradle-idea-ext-plugin
    // Note: The DSL apparently changed in v0.4 since if I upgrade to it or later, the following breaks.
    //       But I have not had the time to dig into it and see what needs to change
    //       The DSL spec is documented on the project's wiki, but it is not the most stellar documentation,
    //       and is only for the Groovy based DSL. When I find some time, I can look at modifying our settings/configurations.
    //       https://github.com/JetBrains/gradle-idea-ext-plugin/wiki
    //       This issue has some links to information/help on using with the Kotlin Gradle DSL:  https://github.com/JetBrains/gradle-idea-ext-plugin/issues/44
    project {
        (this as ExtensionAware)
        configure<ProjectSettings> {
            this as ExtensionAware

            configure<org.jetbrains.gradle.ext.CopyrightConfiguration> {
                useDefault = "Apache 2 -- 2015 inception"
                profiles {
                    create("Apache 2 -- 2015 inception") {
                        this.keyword = "Copyright"
                        this.notice = """
                                    #set( ${'$'}inceptionYear = 2015 )
                                    Copyright ${'$'}inceptionYear#if(${'$'}today.year!=${'$'}inceptionYear)-${'$'}today.year#end the original author or authors.
                                    
                                        Licensed under the Apache License, Version 2.0 (the "License");
                                        you may not use this file except in compliance with the License.
                                        You may obtain a copy of the License at
                                    
                                          https://www.apache.org/licenses/LICENSE-2.0
                                        
                                        Unless required by applicable law or agreed to in writing, software
                                        distributed under the License is distributed on an "AS IS" BASIS,
                                        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                                        See the License for the specific language governing permissions and
                                        limitations under the License.
                                """.trimIndent()
                    }
                }
            }

            configure<org.jetbrains.gradle.ext.EncodingConfiguration> {
                // setting EncodingConfiguration requires IDEA 2019.1+
                this.encoding = "UTF-8"
                this.bomPolicy = org.jetbrains.gradle.ext.EncodingConfiguration.BomPolicy.WITH_NO_BOM
                properties {
                    encoding = "UTF-8"
                    transparentNativeToAsciiConversion = true
                }
            }
        }
    }
}

// region == Utility functions

// allows for the standard task syntax after declaring something like:  val publishPlugin: PublishTask by tasks
inline operator fun <T : Task> T.invoke(a: T.() -> Unit): T = apply(a)

fun systemPropertyGetOrDefault(key: String, default: String) = Pair<String, String>(key, System.getProperty(key, default))

/** Retrieves a project property as a String. */
fun projectProperty(key: String) = project.findProperty(key).toString()
/** Retrieves a project property as a String, using the default value if the property is not defined. */
fun projectProperty(key: String, defaultValue: String) = project.findProperty(key)?.toString() ?: defaultValue
/** Retrieves a project property as a Boolean. */
fun projectPropertyBoolean(key: String) = projectProperty(key).toBoolean()
/** Retrieves a project property as a Boolean, using the default value if the property is not defined. */
fun projectPropertyBoolean(key: String, defaultValue: Boolean) = projectProperty(key, defaultValue.toString()).toBoolean()
/** Retrieves a project property that is a delimited String and returns it as a List of String, or an empty List if the property is not set. */
fun projectPropertyList(key: String, vararg delimiters: Char = charArrayOf(',')): List<String> = project.findProperty(key)?.toString()?.split(*delimiters)?.map { it.trim() } ?: emptyList()

/** Sets a Gradle Property value via a Project Property (usually set in gradle.properties). */
fun Property<String>.setViaProjectProperty(key: String) = this.set(projectProperty(key))
/** Sets a Gradle Property value via a Project Property (usually set in gradle.properties). */
fun Property<String>.setViaProjectProperty(key: String, defaultValue: String) = this.set(projectProperty(key, defaultValue))
/** Sets a Gradle Property value via a Project Property (usually set in gradle.properties). */
fun Property<Boolean>.setBooleanViaProjectProperty(key: String) = this.set(projectPropertyBoolean(key))
/** Sets a Gradle Property value via a Project Property (usually set in gradle.properties), using the default value if the property is not defined. */
fun Property<Boolean>.setBooleanViaProjectProperty(key: String, defaultValue: Boolean) = this.set(projectPropertyBoolean(key, defaultValue))


fun resolvePath(base: String, vararg children: String): String
{
    var file = File(base)
    children.forEach { file = file.resolve(it) }
    return file.absolutePath.toString()
}

fun resolvePathFromProjectRootAsString(vararg children: String): String
{
    return resolvePathFromProjectRoot(*children).toString()
}

fun resolvePathFromProjectRoot(vararg children: String): Path
{
    var path = Path.of(project.rootDir.canonicalPath)
    children.forEach { path = path.resolve(it) }
    return path.toAbsolutePath()
}

fun determineSandboxDir(): String
{
    val ideaVersion = project.findProperty("ideaVersion")?.toString() ?: "UNKNOWN"
    val sandboxSuffix =
        when
        {
            ideaVersion.endsWith("LATEST-EAP-SNAPSHOT", ignoreCase = true)                                        ->
                "LATEST-EAP-SNAPSHOT"
            ideaVersion.contains("""([\d]{3})-EAP-SNAPSHOT""".toRegex(RegexOption.IGNORE_CASE))                         ->
                """[\d]{3}""".toRegex().find(ideaVersion)!!.value
            ideaVersion.contains("""([A-Z]{2}-)?(2[\d]{3})\.[\d](\.[\d]{1,2})?""".toRegex(RegexOption.IGNORE_CASE))     ->
                """(2[\d]{3})\.[\d]""".toRegex().find(ideaVersion)!!.value.substring(2, 6).replace(".", "")
            ideaVersion.contains("""([A-Z]{2}-)?([\d]{3})\.[\d]{1,5}(\.[\d]{1,4})?""".toRegex(RegexOption.IGNORE_CASE)) ->
                """[\d]{3}""".toRegex().find(ideaVersion)!!.value
            else                                                                                                        ->
                ideaVersion
        }

    val sandboxDir = Path.of(project.rootDir.canonicalPath).resolve(".sandboxes").resolve(".sandbox-$sandboxSuffix").toString()
    logger.lifecycle(">>>sandboxDir set to: $sandboxDir")
    return sandboxDir
}

/** Determines if a JBR JDK is available for use. If so returns a "JetBrains" JvmVendorSpec. Otherwise, returns the provided fallback spec. */
fun determineJvmVendor(@Suppress("UnstableApiUsage") defaultFallbackSpec: JvmVendorSpec = JvmVendorSpec.ADOPTIUM): JvmVendorSpec
{
    // @formatter:off
    val jdkDirs = if (System.getProperty("os.name").contains("windows", ignoreCase = true))
        listOf(userHomeDir.resolve(".jdks"))
    else
        listOf(userHomeDir.resolve("Library/Java/JavaVirtualMachines/"), Path.of("/Library/Java/JavaVirtualMachines/"))

    val jbrList = jdkDirs
        .asSequence()
        .map { (it.toFile().listFiles { file -> file.isDirectory && file.name.contains("jbr-$javaVersion") } ?: emptyArray()).asSequence() }
        .requireNoNulls()
        .flatten()
        .toList()
    logger.info("Found jbr JDKs:  $jbrList")
    val spec = if (jbrList.isNotEmpty()) JvmVendorSpec.matching("JetBrains") else defaultFallbackSpec
    println("Using JvmVendorSpec '$spec' for Gradle Java Toolchain")
    return spec
    // @formatter:on
}


/**
 * Loads the token replacement values. These are some values that we would prefer not to commit to 
 * source control. While not secrets per se, they are also not things we want bots to find.
 * The tokens are loaded from a properties file, the location of which is specified by an environment
 * variable. In the event the environment variable is not set (such as on the CI server or when being 
 * built for by contributors or for casual development), stand-in values are used. The tokens primarily 
 * need to be available when a distribution build is being run, or testing of the ErrorReportSubmitter
 * is being done.
 */
fun loadTokenReplacements():MutableMap<String, Any>
{
    // TODO: Let's document this in the README in a "Developing the Plugin" section
    return Properties().apply {
        val key = "FRC_PLUGIN_BUILD_REPLACEMENT_TOKENS_PROPERTIES_FILE"
        val envVar: String? = System.getenv(key)
        if (envVar == null)
        {
            if (!isCiBuild)
            {
                logger.warn("Environment variable not set for build tokens. Build tokens will not be replaced. This is fine for development builds. " + 
                                 "But needs to be resolved for distribution builds by setting the env var: $key")
            }
        }
        else
        {
            val path = Path.of(envVar)
            if (Files.exists(path))
            {
                load(Files.newBufferedReader(path, Charsets.ISO_8859_1))
            }
            else
            {
                if (!isCiBuild)
                {
                    logger.error("Properties file specified for build tokens not found. Build tokens will not be replaced. his is fine for development builds. " + 
                                     "But needs to be resolved for distribution builds. Configured path: $key")
                    throw FileNotFoundException("Properties file specified for token replacements was not found: $path")
                }
            }
        }
        if (isEmpty)
        {
            logger.lifecycle("Using stand-in values for built time token replacements")
            // If the stand-in value changes at all, be sure to update the filtering code in the patchPluginXml
            put("SENTRY_DSN_TEST_AND_QA", "https://example.com/stand-in/value")
            put("SENTRY_DSN_PROD", "https://example.com/stand-in/value")
        }
    }.asSequence().map {
        it.key.toString() to it.value
    }.toMap().toMutableMap()
}

// endregion == Utility functions 
