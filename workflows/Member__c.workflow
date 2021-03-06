<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Name_Field</fullName>
        <field>Name</field>
        <formula>Username__c</formula>
        <name>Update Name Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Username</fullName>
        <actions>
            <name>Update_Name_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Member__c.Username__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Overwrites the Name field with the Username__c field&apos;s value.</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
