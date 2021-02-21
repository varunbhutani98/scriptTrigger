( 1 )
// On Account to create a 'Default' (number of contacts= numbers of employee) contact every time an account is created.


public class Createcontact {
    public static void cont(List<Account> ac){
        List<Contact> con = new List<Contact>();
        for(Account a: ac ) {
            for(Integer i=0; i<a.NumberOfEmployees; i++){
                Contact c = new Contact();
                c.LastName = a.Name;
                c.AccountId = a.id;
                con.add(c); 
            }
           
        }
     insert con;
    }
}

Trigger
trigger AccountTrigger on Account (after insert) {
  
    HelperClass.cont(Trigger.new);
    }

Anonymus

Account  ac = new Account(Name='trigg2',NumberOfEmployees=3);
if(ac.NumberOfEmployees != null){
    insert ac;            
}else{
    System.debug('Enter number of employees');
}



( 2 )
// On Opportunity do not let the user insert Opportunities with past closed Date with following Message "Please enter a future Closed Date"

// Class
public static void oppr(List<Opportunity> op){
         for(Opportunity o: op) {
        if(o.CloseDate < date.today()) {
            o.addError('Please enter a future Closed Date');
            //system.debug('Please enter a future Closed Date');
        }
        
    }
    }

// Trigger

trigger OpportunityTrigger on Opportunity (before insert) {
   HelperClass.oppr(Trigger.new);
}
OR



// Anonymous  window

 Opportunity opp = new Opportunity(CloseDate = Date.newInstance(2021, 1, 15) , Name = 'opptrigger1', StageName= 'Closed Won');
insert opp;



( 3 )
// On Product to setup default Pricebook entry in the “Standard Pricebook” as 1$

// Class 

public static void prod(List<Product2> pr) {
        
    Pricebook2 pbk = [SELECT id FROM Pricebook2 WHERE  IsStandard = true LIMIT 1];
      List<PricebookEntry> pribkentry = new List<PricebookEntry>();
      for(Product2 pr1: pr) {
          
          PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbk.id,Product2Id = pr1.id,UnitPrice = 1,isActive = true);
          pribkentry.add(pbe);
      }
      insert pribkentry;
    }

// Trigger 
trigger TriggerOnProduct on Product2 (after insert) {
    
   if(Trigger.isBefore ) {
        
    }else if(Trigger.isAfter){
        HelperClass.prod(Trigger.new);
    }
			
}

// Anonymous  window

Product2  prd = new Product2(Name = 'Day 15 product');
insert prd;

(  4  )
On Contact to update the Account Name field with contact Last Name, concatenated in the end. Example: If you Create A Contact whose FirstName='Sarthak' and LastName='Saxena' and the Accountname ='Tata', Then Account name must become 'TataSaxena'.


// Class

public static void Cont(List<Contact> Cnt) {
        List<Account> acc = new List<Account>();
       
        for(Contact c: [SELECT LastName,AccountId FROM Contact WHERE  Id in: cnt LIMIT 10]) {
            for(Account a: [SELECT id,Name FROM Account WHERE id =: c.AccountId LIMIT 10]) {
                if(c.AccountId != null){
                    Account ac = new Account();
                    ac.id = a.Id;
                    ac.Name = a.Name + c.LastName;
                    acc.add(ac);
                }
            }
        }
        update acc;
        }

OR

public static void Cont(List<Contact> Cnt) {

Contact acc=[select Accountid,LastName from Contact where id in:conlist];
Account accname=[select Name from Account where id=:acc.Accountid];
accname.name+=acc.LastName;
update accname;
}

// Trigger

trigger TriggerOnContact on Contact (after insert, before insert ) {
    if(Trigger.isBefore ) {
        
    }else if(Trigger.isAfter){
        HelperClass.Cont(Trigger.new);
    }
		
}




 // Anonymous  window 

Account ac = [SELECT id,Name FROM Account WHERE Name = 'varun2' LIMIT 1];
Contact  con = new Contact(FirstName = 'Sarthak', LastName = 'Saxena', AccountId = ac.id);
insert con;



( 5 )
Update the above trigger to delete the Last Name from the Account field when a Contact is deleted without deleting the other Last name.

// Class

public static void delAccLstName(List<Contact> conList) {
if(conList.size()>0)
{
map<id,Account> m2=new map<id,Account>();
Set<id> accId=new Set<id>();
for(Contact cn:[Select id,LastName,AccountId,Account.Name from Contact where id in:conList])
{
if(cn.Account.Name !=Null && cn.Account.Name.length()<255)
{
cn.Account.Name=cn.Account.Name.remove(cn.LastName);
m2.put(cn.AccountId,cn.Account);
accId.add(cn.AccountId);
}
}
List<Account> alist=new List<Account>();
for(Id acId:accId)
{
alist.add(m2.get(acId));
}
Update m2.values();
}
}

OR

 public static void delAccLstName(List<Contact> conList) {
         System.debug('hlo debug');
        contact con=[select LastName,Accountid from contact where id in:conList];
        Account acc=[select Name from Account where id =:con.AccountId];
        acc.name=acc.name.remove(con.LastName);
       update(acc);    
    }



// Trigger 

trigger TriggerOnContact on Contact (after insert, before insert, before delete ) {
    if(Trigger.isDelete && Trigger.isBefore) {
        HelperClass.delAccLstName(Trigger.old);
    }else if(Trigger.isAfter){
        HelperClass.Cont(Trigger.new);
    }else if ( Trigger.isBefore) {
        
    }
		
}


// Anonymous  window 

List<Contact> con = [Select id from Contact where LastName like 'Saxena' limit 1];
Delete con;







( 6 )
On Opportunity to alert the user when an Opportunity is being closed with no Opportunity line items in it.


// Class

public static void opportunityClosed(List<Opportunity> oppLst) {
        
        if(!oppLst.isEmpty()) {
            for(Opportunity o: oppLst) {
                if((!o.HasOpportunityLineItem)&& (o.StageName == 'Closed Won' || o.StageName == 'Closed Loss' )) {
                  //  o.addError('Opportunity is being closed with no Opportunity line items in it');
                  Set<id> opid = new Set<id>();
        for(Opportunity op: oppLst) {
            opid.add(op.OwnerId);
        }
        if(opid.size() > 0) {
            list<User> ulist=[Select id,Email from User Where Id in:opid and Email !=''];
		System.debug(ulist);
		String[] s = New List<String>();
		For(User u : ulist){
		s.add(u.Email);
		}
		if(s.size()>0){
		messaging.SingleEmailMessage email1=new messaging.SingleEmailMessage();
		email1.setToAddresses(s);
        email1.setSubject('Opportunity is being closed with no Opportunity line items in it');
		email1.setPlainTextBody('Hello Dear User!');
		email1.setSenderDisplayName('Trigger Script');
		messaging.Email[] emails = new messaging.Email[]{email1};
		messaging.sendEmail(emails);
		}
        }  
                }
       		 }
        }
}



// Trigger

if (Trigger.isAfter && Trigger.isInsert) {
        HelperClass.opportunityClosed(Trigger.new);
    }

// Anonymous  window 

Opportunity opp = new Opportunity(Name = 'OppCloseNoOPPLineItem', StageName = 'Closed Won', CloseDate = Date.today().addDays(2));
insert opp;


( 7 )
Create a trigger on Opportunity to add all the Contacts having the same Account as Opportunity.Account into the Opportunity "Contact Roles"
Example:- Account: Birla have 3 Contacts: ajay,amar,anuj Then while creating an Opportunity for Birla add ajay,amar & anuj to Opportunity Contact roles--T





// Class

public static void addContoOpportunity(List<Opportunity> oppList) {
       
        list<OpportunityContactRole> oppConRol=new list<OpportunityContactRole>();
        for(Opportunity op: oppList) {
            for(Contact con: [SELECT id FROM Contact WHERE Accountid =: op.Accountid]) {
                OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = op.id, ContactId = con.id);
                oppConRol.add(ocr);
            }
        }
      //  System.debug(oppConRol);
        insert oppConRol;
    }



// Trigger

if (Trigger.isAfter) {
        if(Trigger.isInsert) {
             HelperClass.addContoOpportunity(Trigger.new);
        }
       
    }


  // Anonymous  window 

List<Account> acc = [SELECT id,Name FROM Account LIMIT 1];
// System.debug(acc);
Opportunity opp = new Opportunity(Name = 'Opp acc varun1 trigger Day16', StageName = 'Closed Won',AccountId = acc[0].id, CloseDate = Date.today().addDays(10));
// System.debug(opp);
insert opp;


( 8 )
On campaign to close all the opportunities associated with the campaign when campaign status is completed. Example:Opportunities having line items in it must be closed won and opportunities having no line item must be closed lost.

// class

 public static void campaignOpportunity(List<Campaign> campaignList) {
        System.debug(campaignList);
List<Campaign> campaignList2=new List<Campaign>();
for(Campaign cm:campaignList){
if(cm.Status=='completed'){
campaignList2.add(cm);
}
}
if(!campaignList2.isEmpty()){
List<opportunity> oppList=[Select id,CampaignId from Opportunity where CampaignId in:campaignList2 Limit 1000];
if(!oppList.isEmpty()){
List<OpportunityLineItem> oppLineItemList=[Select id,OpportunityId from OpportunityLineItem where opportunityId in:oppList];
Set<Id> oppId=new Set<Id>();
for(OpportunityLineItem opLine:oppLineItemList){
oppId.add(opLine.OpportunityId);
}
for(Opportunity opp:oppList){
if(oppId.contains(opp.id)){
opp.StageName='Closed Won';
}
else{
opp.StageName='Closed Lost';
}
}
update oppList;
}
}
}


// Trigger

trigger TriggerOnCampaign on Campaign (before insert, before update, after update,after insert) {
			
    if(Trigger.isUpdate && Trigger.isAfter) {
        HelperClass.campaignOpportunity(Trigger.new);
    }
    
}


//  // Anonymous  window 

Campaign cmpn = new Campaign(Name = 'Camp2',IsActive = true,Status = 'completed');
insert cmpn;

( 9 )
Bulkify the above trigger.

( 10)
Write a Trigger to stop add more than 2 Opportunity line Items records in an Opportunity.
// class
 public static void stopOpportunityLineItem(List<OpportunityLineItem> oppList) {
         Set<id> oppid = new Set<id>();
             if(!oppList.isEmpty()){
                 for(OpportunityLineItem oli: oppList) {
            				oppid.add(oli.OpportunityId);
                     
                     List<OpportunityLineItem> lineItems = new  List<OpportunityLineItem>();
           lineItems = [SELECT id FROM OpportunityLineItem WHERE OpportunityId =: oppid];
                     
                     if(lineItems.size() > 1) {
                         System.debug('working');
                         oli.addError('You are not allow to add more than 2 LineItems');
                     }
                     
        			} 
             }
       
   }
// Trigger
trigger TriggerOnOpportunityLineItem on OpportunityLineItem (before insert) {
		
    if(Trigger.isBefore && Trigger.isInsert) {
            HelperClass.stopOpportunityLineItem(Trigger.new);
       
        }
}


		            // Anonymous  window 

PricebookEntry pbe = [select id from PriceBookEntry limit 1];
list<Product2> pro=[Select id from Product2 limit 3];
Opportunity opp=[Select id,name from Opportunity limit 1];
list<OpportunityLineItem> oli=new list<OpportunityLineItem>();
for(Product2 p:pro)
{
OpportunityLineItem oli2=new OpportunityLineItem();
oli2.Quantity=100.00;
oli2.OpportunityId=opp.id;
oli2.TotalPrice=200;
oli2.Product2Id=p.id;
oli2.PriceBookEntryId=pbe.id;
oli.add(oli2);
}
insert oli;



( 11 )
Write a Trigger to create a default Contact, Case, Opportunity and Contact Role. whenever an Account is created with a Number of Employees > 100. Make sure the Contact is in the contact field of Case as well as related to Opportunity inn Contact Role.

// Class

→ In this program we created case and opportunity and we did not created contact and Contact Role Here Because it is automatically created by Previous Trigger

    public static void createConCaseOppoConRole(List<Account> acList) {
        if(!acList.isEmpty()) {
            
            
           List<Case> cas = new List<Case>();
      List<Opportunity> lstopp = new List<Opportunity>();

for(Account a : acList){
if(a.NumberOfEmployees != Null && a.NumberOfEmployees>100 ){
Opportunity op = new Opportunity();
op.Name = 'Mobile'+a.Name;
op.AccountId = a.Id;
op.CloseDate = Date.today().addDays(10);
op.StageName = 'Qualification';
lstopp.add(op);

Case cs = New Case();
cs.Status = 'Working';
cs.AccountId = a.Id;
cas.add(cs);
}
}
Insert lstopp;
Insert cas;
        
}
   
   }


// Trigger

trigger AccountTrigger on Account (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        HelperClass.createcont(Trigger.new);
       HelperClass.createConCaseOppoConRole(Trigger.new);
    }
    if(Trigger.isAfter ) {
         }
} 


   // Anonymous  window 

List<Account> accList = new List<Account>();
for(integer i=0; i<2; i++) {
    Account acobj = new Account();
acobj.Name = 'Realme7' + i;
acobj.NumberOfEmployees = 102;    

accList.add(acobj);
}
insert accList;



( 12 )
Write a trigger on Opportunity to create a new Case with all case fields should have default values whenever an Opporutnity is getting closed lost.

// Class

public static void createNewCase(List<Opportunity> opList) {
            
        	set<id> se = new set<id>();
			list<Case> cas = new list<Case>();
			for(Opportunity o: opList){
			if(o.StageName.contains('Closed')){
			se.add(o.AccountId);
                system.debug(se);
           
			 }
			}

	list<Contact> con = [select id from Contact where AccountId in:se limit 1];
             system.debug(con);
			for(Opportunity o: opList)
			{
			for(Contact c: con)
			{
			Case ca= new Case();
			ca.AccountId = o.AccountId;
			ca.ContactId = c.Id;
			cas.add(ca);
			}
			}
   		     System.debug(cas);
			insert cas;
        
    }


// Trigger

trigger OpportunityTrigger on Opportunity (before insert, after insert, after update, before update) {
   
    if(Trigger.isInsert && Trigger.isBefore) {
        HelperClass.oppr(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
      //  HelperClass.opportunityClosed(Trigger.new);
    } 
    if (Trigger.isAfter) {
        if(Trigger.isInsert) {
             HelperClass.addContoOpportunity(Trigger.new);
        }
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        HelperClass.createNewCase(Trigger.new);
    }
}


   // Anonymous  window 

Opportunity o=[Select id,Name from Opportunity Where AccountId !='' limit 1];
o.StageName='Closed Lost';
system.debug(o);
update o;



( 13 )
Write a Trigger to Stop creating any more Plan records with location 'A' if we have Travel Hours more than 100 for any specific location 'A'. Example
If total hours of all the Plans for A is 90 and B is 70 and C is 100 and
> a new Plan is getting created with A hours 5. Trigger should not stop as total hours will become 95
> a new Plan is getting created with B hours 45. Trigger should stop as total hours will become 105.

// Class

public static void travelHoursForPlan(List<Plan__c> planList) {
        
        if(!planList.isEmpty()) {
        List<Plan__c> planList2 = [select Travel_Hours__c from Plan__c where Travel_Location__c ='A'];
        System.debug('planList2' +planList2);
        
        Decimal totalHour = 0;
        for(Plan__c pl1: planList2) {
            totalHour = totalHour + pl1.Travel_Hours__c;
        }
        for(Plan__c pl2: planList) {
            if(totalHour + pl2.Travel_Hours__c > 100 && pl2.Travel_Location__c =='A') {
                pl2.addError('You Can not add more hour Into Location --> A');
            }
        }
        
        }
        
        if(!planList.isEmpty()) {
        List<Plan__c> planList2 = [select Travel_Hours__c from Plan__c where Travel_Location__c ='B'];
        System.debug('planList2' +planList2);
        
        Decimal totalHour = 0;
        for(Plan__c pl1: planList2) {
            totalHour = totalHour + pl1.Travel_Hours__c;
        }
        for(Plan__c pl2: planList) {
            if(totalHour + pl2.Travel_Hours__c > 100 && pl2.Travel_Location__c =='B') {
                pl2.addError('You Can not add more hour Into Location --> B');
            }
        }
        
        }
        
	}
//////////////////////////////////////////////   OR   //////////////////////////////////////////////////////////////////////////////////////

 if(!Planlist.isEmpty())
		{
		double hours=0;
		for(INTEGER counter=0;counter<planlist.size();counter++)
		{
		for(Plan__c pl:planlist)
		{
		String query1 = 'Select Travel_Hours__c,Travel_Location__c From plan__c Where Travel_Location__c includes(\''+pl.Travel_Location__c+'\')';
		List <plan__c> plans = Database.query(query1);
		for(Plan__c p:plans)
		{
		hours+=p.Travel_Hours__c;
		}
		if(hours+pl.Travel_Hours__c>100)
		{
		pl.AddError('Plan Hour Greater then 100');
		}
			}
		}
	}


// Trigger

trigger TriggerOnPlan on Plan__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        HelperClass.travelHoursForPlan(Trigger.new);
    }
}

// Anonymous Window

Plan__c  pln = new Plan__c();
pln.Name = 'My new Plan';
pln.Travel_Location__c = 'A';
pln.Travel_Hours__c = 68;

insert pln;

Plan__c  pln2 = new Plan__c();
pln.Name = 'My new Plan2';
pln.Travel_Location__c = 'B';
pln.Travel_Hours__c = 101;

insert pln2;

////////////////////////////////  OR  ////////////////////////////////////////////////////////////////////////

List<Plan__c> planlist=new List<plan__c>();
List<String> location=new List<String>{'A','B','c'};
for(integer i=0;i<3;i++)
{
Plan__c Plan=new Plan__c();
Plan.Name='Shimla';
Plan.Travel_Hours__c=80;
Plan.Travel_Location__c=location[i];
Planlist.add(Plan);
}
Database.Insert(planlist,False);






( 14 )
Please solve the script question first.
Script -
Create an Object "Event" (Name Default field and "Event Date" Date time field). Another Junction Object "Event Participant" with 3 fields
1. lookup Contact
2. lookup Event
3. picklist ("Attendee Contact", "Presenter Contact","Organizer Contact")
Write a script to create 10 "Event Participant" with Attendee picklist, 4 with Presenter, 2 with organizer.

Write a trigger to make sure No Event is having the same Contact registered as Attendee twice
Explanation : A user is not allowed to create Two Event participant with same contact Lookup value under same Event .

// Class

 public static void eventParticipant(List<Event_Participant__c> evtPrt) {
        
        List<Event_Participant__c> eplist=[SELECT Id,Contact__c,Event__c from Event_Participant__c where Contact__c != NULL and Event__c !=NULL];
        for(Event_Participant__c epc: evtPrt) {
            for(Event_Participant__c cc: eplist) {
                if(epc.Contact__c == cc.Contact__c && epc.Event__c == cc.Event__c) {
                   epc.addError(' No Event will have the same Contact registered as Attendee twice!!!'); 
                }
            }
        }
        }


// Trigger

trigger TriggerOnEventParticipant on Event_Participant__c (before insert, before update) {
		if(trigger.isBefore && trigger.isInsert)
		{
		HelperClass.eventParticipant(trigger.new);
		}
}
// Anonymous Window

// You can directly create Event_Participant__c  Record from ui or can create in anonymous window also

List<Event_Participant__c> evptList = new List<Event_Participant__c>();
Contact__c   cnt = [select id from Contact__c limit 1];
Event__c	 evt = [select id from Event__c	 limit 1];

Event_Participant__c evptObj = new Event_Participant__c();

evptObj.Contact__c = cnt.id;
evptObj.Event__c = evt.id;

evptList.add(evptList);


( 15 )
Script -
Create an Object "Event" (Name Default field and "Event Date" Date time field). Another Junction Object "Event Participant" with 3 fields
1. lookup Contact
2. lookup Event
3. multipicklist ("Attendee Contact", "Presenter Contact","Organizer Contact")
Write a script to create 10 "Event Participant" with Attendee picklist, 4 with Presenter, 2 with organizer.
Trigger -
Write a trigger to stop creating "Event Participant" if a Contact is registering for 2 Events happening in Same day ie. Event Date is same.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
First create two Events in  Sales Cloud , created date must be same
Than goto event participant in salecloud, create a new record of this
Select any contact c1  and any event say event 1
Now create another eventparticiapant record having contact c1 and event 1

This Should error , because one contact can registering for one event in same day 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Class

	public Static void checkEventDate(List<Event_Participant__c> ep){
		
        system.debug('start of function');
		list<Event_Participant__c> epc = [select id,Event__c,Event__r.Event_Date__c,Contact__c from Event_Participant__c limit 10];
		set<id> se = new set<id>();
		Map<id, datetime> eveDate = new Map<id, datetime>();
		for(Event_Participant__c e : ep)
		{
		se.add(e.Contact__c);
		se.add(e.Event__c);
		}

	list<Event__c> event = [select id,Event_Date__c from Event__c where id in:se limit 10];
		for(Event__c ev: event)
		{
		if(!eveDate.containskey(ev.id))
		{
		eveDate.put(ev.id, ev.Event_Date__c);
		}
		}

		for(Event_Participant__c e: ep)  // new event_participant List
		{
		for(Event_Participant__c e1: epc)  // // old event_participant List
		{
		if(e.Event__c!= e1.Event__c)
		{
		datetime nowdd = eveDate.get(e.Event__c);//now
		datetime lastdd = e1.Event__r.Event_Date__c;//last
		system.debug(lastdd);
		system.debug(nowdd);
		if(e.Contact__c == e1.Contact__c)
		{
		if(lastdd == nowdd)
		{
		e.addError('Contact is registering for 2 Events happening in Same day');
		}
		}
		}
	}

	}

}


// Trigger

trigger TriggerOnEventParticipant on Event_Participant__c (before insert, before update) {
		if(trigger.isBefore && trigger.isInsert)
		{
		HelperClass.eventParticipant(Trigger.new);
        HelperClass.checkEventDate(Trigger.new);    
		}
}




( 16 )
Script -
In Account Object create a Multi picklist "Working in (ASIA, EMA, NA, SA)".
Write a script to get the total "No of employees" of all the Accounts working in ASIA and NA(North America)
Trigger -
Create 4 Pricebooks ASIA, EMA, NA and SA. Write a trigger on Opportunity which should not allow user to add a Pricebook in the Opportunity which is not present in Account Multipicklist Working in (ASIA, EMA, NA, SA)".

// Class 

		public static void CheckPick(list<Opportunity> opp)
    {
        system.debug('hello varun');
        set<id> se = new set<id>();
        Map<id, string> accWorking = new Map<id, string>();
        Map<id, string> pbName = new Map<id, string>();
        for(Opportunity o : opp)
        {
            se.add(o.AccountId);
            se.add(o.Pricebook2Id);
            system.debug('1');
        }
        
        list<Pricebook2> pr = [select name from pricebook2 where id in:se];
        list<Account> acc = [select working_in__c from Account where id in:se];
        
        system.debug(pr);
        system.debug(acc);
        
        for(Account a : acc)
        {
            if(!accWorking.containskey(a.Id))
            {
                accWorking.put(a.Id,a.Working_in__c);
            }
        }
        for(Pricebook2 p:pr)
        {
            if(!pbName.containskey(p.Id))
            {
                pbName.put(p.Id,p.Name);
            }
        }
        for(Opportunity oo:opp)
        {
            system.debug('101');
            string working = accWorking.get(oo.AccountId);
            string name = pbName.get(oo.Pricebook2Id);
            if(!working.contains(name))
            {
                oo.addError('not allowed');
            }
        }
    }


// Trigger

if(Trigger.isBefore && Trigger.isUpdate) {
        HelperClass.CheckPick(Trigger.new);
    }





( 17 )
Write a Script to get all the Contacts having same email as any Salesforce User.Email
Trigger -
Write a trigger on Contact to copy Current User Address in Contact Address and Account Billing Address
only when any adress field(Street, Country, state )is blank/NULL.

// Class

  		public static void UpdateContactAccountAddress(List<Contact> con){
        User usr=[Select id,Name,Country,State,Street,City from User where id =: UserInfo.getUserId()];
        System.debug(usr);
            
        for(contact c:con){
            if(c.MailingStreet==Null && c.MailingCountry==Null && c.MailingState==Null && c.MailingCity==Null){
                c.MailingStreet=usr.Street;
                c.MailingCountry=usr.Country;
                c.MailingState=usr.State;
                c.MailingCity=usr.City;
            }
        }
        Set<Id> conIdSet=new Set<Id>();
        for(Contact c:con)
        {
            conIdSet.add(c.AccountId);
        }
        
        List<Account> accList=[Select id,Name,BillingCountry,BillingState,BillingStreet,BillingCity from Account where id In : conIdSet];
        for(Account acc:accList)
        {
            if(acc.BillingStreet==Null && acc.BillingCountry==Null && acc.BillingState==Null && acc.BillingCity==Null)
            {
                acc.BillingStreet=usr.Street;
                acc.BillingCountry=usr.Country;
                acc.BillingState=usr.State;
                acc.BillingCity=usr.City;
                
        }
        update accList;
    }
}


   					// Trigger

trigger TriggerOnContact on Contact (after insert, before insert, before update, after update,before delete ) {
    if(Trigger.isDelete && Trigger.isBefore) {
        HelperClass.delAccLstName(Trigger.old);
    }
    if(Trigger.isAfter && Trigger.isInsert ){
        HelperClass.Cont(Trigger.new);
        
        
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        HelperClass.UpdateContactAccountAddress(Trigger.new);
    }
}


( 18) 
Script -
Create several Contacts with both Mailing and Shipping Address value filled. Make sure your current user details from Setup>> User>> details have adress value filled in too. Write a Script to get all the contacts having same Mailing Country in Address as Current User Address Mailing Country.
Trigger -
Create a checkbox field "SAME COUNTRY AS USER & COMPANY" in Contact. Write Trigger to throw error when a Contact is getting inserted in Salesforce having Country same as User country and Company country

				// Class

    public static void sameCountryAsUserAndContact(List<Contact> cntLst) {
        
        Set<id> cnOwnrId = new Set<id>();
        for(Contact c: cntLst) {
            cnOwnrId.add(c.OwnerId);
        }
        
        User u=[Select Country from User Where id =: cnOwnrId limit 1];
        Organization org=[Select Country from Organization limit 1];
        
        for(Contact c: cntLst) {
            if(c.SAME_COUNTRY_AS_USER_COMPANY__c == true)
            {
                if(u.Country != c.MailingCountry && org.Country != c.MailingCountry)
                {
                    c.addError('Country is must be same as user country');
                }
            }
        }
     }

                                                 // Trigger

if(Trigger.isBefore && Trigger.isInsert) {
        HelperClass.fillContactMailingAddreessWithAccShipAddress(Trigger.new);
        HelperClass.sameCountryAsUserAndContact(Trigger.new);
    }




( 19 )
Script -
Create a look up[Lead] on product so that Products come over in related list of a Lead. Write script to create 3 Leads and 5 Products with Lead lookup field.
Trigger -
Write a Trigger to stop creating or updating Opportunities with Account having "Working in = ASIA" and Already 2 Closed Won Opportunity under same Account.

→  In this question we have to create account working in ASIA  in UI and Trying to add Opportunity with stageName = Closed Won , but we can add max 2 opportunity to account

// Class


    public static void stopCreatingUpdatingOpprtunity(List<Opportunity> opprlst) {
        
        if(!opprlst.isEmpty()) {
           List<Account> AccList=[Select Name,Id from Account Where Working_In__c includes('ASIA')];       
       List<Opportunity> Oppwonlst=[Select Id, AccountId From Opportunity Where StageName='Closed Won' and AccountId IN:AccList]; 
       for(Opportunity Opp:opprlst)
            {
               Integer sum=0;
              for(Opportunity opp1:Oppwonlst)
              {
                 if(opp1.AccountId==Opp.AccountId)
                 {
                    sum++;
                 }
               }
                if(sum>1)
                {
                  Opp.addError('CAN NOT ADD OR UPDATE NEW OPPORTUNITY !!');
                }
            } 
        }
        
        
    }


                                                          // Trigger
if(Trigger.isInsert && Trigger.isBefore) {
        HelperClass.oppr(Trigger.new);
        HelperClass.stopCreatingUpdatingOpprtunity(Trigger.new);
    }


( 20 )

// "Script - 
// Create a Script to find out all the users in the systems who are having more than 20 Leads allocated[Owner] to them in month of Dec 2017
// Trigger - 
// Write a Trigger on lead to show error message when a lead is getting allocated[Owner] to a user 
// when the Owner User has reached the limit of 30 Lead owner in a particular month."

				// Class

    public static void leadLimit(List<Lead> ldList) {
        
         list<Lead> lead1=[Select OwnerId,CreatedDate from Lead Where CreatedDate = THIS_MONTH limit 100];
     
        System.debug(lead1);
        for(Lead l1:ldList)
        {
            System.debug(l1);
             Integer count=0;
            for(Lead l2:lead1)
            {
                System.debug(l2);
                if(l1.OwnerId == l2.OwnerId)
                {
                  count++;
                }    
            }
            if(count >= 30)
            {
                l1.addError('limit is reached');
            }
        }
    }

/////////////////////////////////////////////// OR //////////////////////////////////////////////////////////////////////////////

  public static void leadLimit(List<Lead> ldList) {
        
         list<Lead> lead1=[Select OwnerId,CreatedDate from Lead Where CreatedDate = THIS_MONTH limit 100];
     
        System.debug(lead1);
        
        if(ldList.size() + lead1.size() > 30) {
            for(Lead ld: ldList) {
                ld.addError('Can Not create lead more than 30');
            }
        }
    }


			// Trigger

trigger TriggerOnLead on Lead (before insert) {
    if(Trigger.isBefore && Trigger.isInsert) {
        HelperClass.leadLimit(Trigger.new);
    }
}





( 21 )
Write a trigger on Contact and fill its Mailing Address with its Account's Shipping Address.

// class

    public static void fillContactMailingAddreessWithAccShipAddress(List<Contact> conLst) {
        
        if(!conlst.isEmpty()){
            List<Id> l = new List<id>();
        for(Contact c: conLst){
            l.add(c.AccountId);
        }
            List<Contact> cnList = new List<Contact>();
       Account ac = [select id,name,ShippingStreet,ShippingCountry,ShippingState,ShippingCity FROM Account where id in: l limit 1];
        
            
            for(Contact c: conlst) {
                if(c.MailingStreet==Null && c.MailingCountry==Null && c.MailingState==Null && c.MailingCity==Null){
				c.MailingStreet = ac.ShippingStreet;
                c.MailingCountry = ac.ShippingCountry;
                c.MailingState = ac.ShippingState;
                c.MailingCity = ac.ShippingCity;
            }
               cnList.add(c); 
            }
        }
      
    }


                                                                 // Trigger
trigger TriggerOnContact on Contact (after insert, before insert, before update, after update,before delete ) {
    if(Trigger.isDelete && Trigger.isBefore) {
        HelperClass.delAccLstName(Trigger.old);
    }
    if(Trigger.isAfter && Trigger.isInsert ){
        HelperClass.Cont(Trigger.new);
        
        
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        HelperClass.UpdateContactAccountAddress(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isInsert) {
        HelperClass.fillContactMailingAddreessWithAccShipAddress(Trigger.new);
    }
}




( 22 )
Create a CheckBox with 'Allow Multiple' on Account Object when this CheckBox is Checked user can create Multiple Contacts within its Account associated and when it is UnChecked user cannot able to create Multiple Contacts.



// Class 

    public static void accountcheckbox(list<Contact> con)
    {
       
        set<id> conId=new set<id>();
        for(Contact c:con)
        {
            conId.add(c.AccountId);
        }
        Account acc=[Select id,Allow_Multiple__c from Account Where id in:conId limit 1];
        list<Contact> con1=[Select id,AccountId from Contact Where AccountId =: acc.id limit 10];
        
        for(Contact c:con)
        {
             Integer i=0;
            for(Contact c1:con1)
            {
                if(c.AccountId==c1.AccountId)
                {
                    i++;
                }
             }  
                if(i>=2 && acc.Allow_Multiple__c != True)
                {
                    
                    c.addError('donot add multiple contacts');
                
                    
                }   
            
        }
    }



