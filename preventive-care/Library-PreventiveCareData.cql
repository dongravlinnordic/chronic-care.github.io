// # Introduction

// The Preventive Care Data logic library supports data retrieval for decision support.

library PreventiveCareData version '1.0.0'

// # Data model #

using FHIR version '4.0.1'

// # Referenced libraries #

// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR R4 data model.
include FHIRHelpers version '4.0.1' called FHIRHelpers
// The CDS Connect Commons for FHIRv400 library provides functions representing commonly used CDS logic and patterns.
include CDSConnectCommons version '1.0.0' called C3F
// The PreventiveCareConcepts library provides terminology concepts used to identify data elements throughout the artifact.
include PreventiveCareConcepts version '1.0.0' called PCC

// # CDS logic #

context Patient

// # General definitions based on value sets and codes #

define "Patient Name":
 Coalesce(Patient.name[0].text.value,
   (Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '))
 )

define "Patient Birth Sex":
  First(Patient.extension e
      where e.url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex'
  ).value.value

define "Patient Race":
  (flatten (
    Patient.extension Extension
      where Extension.url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'
        return Extension.extension
  )) E
    where E.url = 'ombCategory'
      or E.url = 'detailed'
    return E.value as Coding

define "Patient Race Text":
  First((flatten (
    Patient.extension Extension
      where Extension.url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race'
        return Extension.extension
  )) E
    where E.url = 'text'
    return (E.value as FHIR.string)).value

// # Preventive Care logic #

define "Patient is male":
  Patient.gender = 'male'

define "Patient is female":
  Patient.gender = 'female'

define "Race is African American":
  "Patient Race" contains PCC."Black or African American"

define "Patient is 40 or older":
  AgeInYears() >= 40

// Returns a FHIR.Reference, or null if not present.
define "Patient PCP":
  First(Patient.generalPractitioner)

// Reference to a Practitioner resource
// TODO Resolve Practitioner reference if display value is missing
define "Patient PCP name":
  Coalesce({"Patient PCP".display.value, 'Your Doctor'})

// # Patient diagnoses

define "All active conditions":
  C3F.Confirmed(C3F.ActiveOrRecurring([Condition]))
