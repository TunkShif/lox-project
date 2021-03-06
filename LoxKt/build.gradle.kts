import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    kotlin("jvm") version "1.6.10"
    id("com.github.johnrengelman.shadow") version "7.1.2"
    application
}

group = "one.tunkshif"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(kotlin("test"))
}

tasks.test {
    useJUnitPlatform()
}

tasks.withType<KotlinCompile> {
    kotlinOptions.jvmTarget = "1.8"
}

application {
    mainClass.set("one.tunkshif.loxkt.LoxKt")
}

//tasks {
//    shadowJar {
//        manifest {
//            attributes("Main-Class" to "one.tunkshif.loxkt.LoxKt")
//        }
//    }
//}