Class dc.demo.imap.IMAPProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="dc.demo.imap.IMAPProduction" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="dc.demo.imap.IMAPTestService" Category="" ClassName="dc.demo.imap.IMAPTestService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="POP3Port">993</Setting>
    <Setting Target="Adapter" Name="POP3Server">imap.mail.yahoo.com</Setting>
    <Setting Target="Adapter" Name="Credentials">imap-test</Setting>
    <Setting Target="Adapter" Name="SSLConfig">ISC.FeatureTracker.SSL.Config</Setting>
    <Setting Target="Adapter" Name="Mailbox">production</Setting>
  </Item>
  <Item Name="dc.demo.imap.IMAPTestSendEmailOperation" Category="" ClassName="dc.demo.imap.IMAPTestSendEmailOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="Credentials">imap-test</Setting>
    <Setting Target="Adapter" Name="SMTPPort">465</Setting>
    <Setting Target="Adapter" Name="SMTPServer">smtp.mail.yahoo.com</Setting>
    <Setting Target="Adapter" Name="From"></Setting>
    <Setting Target="Adapter" Name="Recipient"></Setting>
    <!-- <Setting Target="Adapter" Name="SSLCheckServerIdentity">1</Setting> -->
    <Setting Target="Adapter" Name="SSLConfig">ISC.FeatureTracker.SSL.Config</Setting>
  </Item>
</Production>
}

}
