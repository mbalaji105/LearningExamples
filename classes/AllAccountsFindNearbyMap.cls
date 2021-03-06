public with sharing class AllAccountsFindNearbyMap {

public Boolean searchLeads {get;set;}
public Boolean searchAccounts {get;set;}
public Boolean searchContacts {get;set;}
public Boolean OnlyMyRecords{get;set;} 
public Boolean pAccounts = false;  

public Boolean ListAccounts = false;  
public Boolean ListLeads = false;  
public Boolean ListContacts = false;  

public String distance;
public Boolean needFilters{get;set;}

public List<MapItem> locs = new List<MapItem>();
public List<MapItem> destinations = new List<MapItem>();
public MapItem startingPoint {get;set;}
public String StartingAddress {get;set;}

public Map<String, MapItem> locationMap = new Map<String, MapItem>{};
public List<SelectOption> AccountTypeOptions = new List<SelectOption>();
public List<SelectOption> AccountIndustryOptions = new List<SelectOption>();

public List<MapItem> getDestinations(){return destinations;}

public String getDistance(){ return distance+'';}

public String[] AccountTypes = new String[]{'All'};
public String[] AccountIndustries = new String[]{'All'};
public String[] LeadStatuses = new String[]{'All'};

public void setAccountTypes(String[] s){ AccountTypes = s;}
public String[] getAccountTypes(){return AccountTypes;}
public void setAccountIndustries(String[] s){ AccountIndustries = s;}
public String[] getAccountIndustries(){return AccountIndustries;}
public void setLeadStatuses(String[] s){ LeadStatuses = s;}
public String[] getLeadStatuses(){return LeadStatuses;}
public boolean LeadsAvailable,ContactsAvailable,AccountsAvailable; 
public boolean getAccountsAvailable(){
	try{
		FindNearby__c FNA = FindNearby__c.getOrgDefaults();
    	AccountsAvailable = FNA.Accounts__c;
	}
	catch(Exception e){AccountsAvailable=false;}
    return AccountsAvailable;
}

public String getGKey(){ 
	findNearby__c settings = findNearby__c.getInstance();
    if(settings.GKey__c == null)
    {
    	return ' ';
    }
    return settings.GKey__c;
	
}


public PageReference init(){
    //reset variables to default.
    needFilters=true;
    distance = '25';  
    onlyMyRecords=true;
    searchAccounts = getAccountsAvailable();
     HandleListViews();
    setAccountTypeOptions();
    hasPersonAccounts(); 
    setAccountIndustryOptions();
    return setStartingPoint();
    
} 

public void HandleListViews(){
    handleAccountListView();
    
}

public void handleAccountListView(){
        String Alids = ApexPages.currentPage().getParameters().get('alids');
        List<String> ids = new List<String>();
            
            try{
                List<Account> asd= [Select  OwnerId, Mapping_Status__c, Id,  Name, Lat__c,Lon__c,Phone, 
                    BillingStreet, BillingCity,BillingState, BillingPostalCode, BillingCountry, 
                    Which_Address__c,ShippingStreet,ShippingCity,ShippingState,Type, Industry, 
                    ShippingPostalCode,ShippingCountry, Owner.Name,Account_Status__c from Account
                    where  Mapping_Status__c ='Located' and billingcountry='UK' limit 50000]; 
                startingAccountid=asd[0].id;
                for(Account a: asd){
                    locs.add(new MapItem(a));
                }
                ListAccounts = true; 
            }
            catch(Exception e){
            
            }
       
}


public void setDistance(String d){ 
    try{
        Decimal a = Decimal.valueOf(d);
        if(a>200){
            distance = '25';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Distance must be less than 200 miles');
            ApexPages.addMessage(myMsg);
            
        }
        else{
            distance = d;
        }
    }
    catch(Exception e){
        //If it's not a decimal.
        distance = '25';
    }

    
}

public String startingAccountid{get;set;}//Declared on August 26 2013 for setting starting Point

public PageReference setStartingPoint(){
    if(locs.size() == 0 && !needFilters){
        return Page.MapError_BadListView;
    }
    else if(!needFilters){
        
        startingPoint =locs[0];
        startingPoint.rName= 'List View';
    }
    
    
    if(needFilters){
        String sID = ApexPages.currentPage().getParameters().get('lid');    
            if(startingAccountid !='null' && startingAccountid !=null){ 
                Account a = MapUtility.getSingleAccountToPlot(startingAccountid);
                startingPoint = new MapItem(a);
            }
    } 


    if(startingPoint == null)
    {
        return Page.MapError_NoStartingPoint;
    }
     
    return null;
}


    
     
    
    
public List<MapItem> getLocations(){
    locs = new List<MapItem>();
    try{
             //filterLocs();
            //Added on August 26,2013
             List<Account> asd= [Select  OwnerId, Mapping_Status__c, Id,  Name, Lat__c,Lon__c,Phone, 
                    BillingStreet, BillingCity,BillingState, BillingPostalCode, BillingCountry, 
                    Which_Address__c,ShippingStreet,ShippingCity,ShippingState,Type, Industry, 
                    ShippingPostalCode,ShippingCountry, Owner.Name,Account_Status__c from Account
                    where  Mapping_Status__c ='Located' and billingcountry='UK' and Owner.id=:Userinfo.getuserID() limit 50000]; 
                startingAccountid=asd[0].id;
                for(Account a: asd){
                    locs.add(new MapItem(a));
                }
            
            	filterLocs();
                sortLocs();
       		 makeMap();
    }
    catch(Exception e){
        sortLocs();
        makeMap();
    }
    System.debug('Locs size:'+locs.size());
    return locs;
}


/*
Instead of Customizing the Query... which can get cumbersome.
Query more - Remove After the fact. 

*/
public void filterLocs(){
    filterAccountType();
}
public void filterAccountType(){
    //Check if ALL has been selected. 
    Boolean all=false;
    for(String i: AccountTypes){
        if(i == 'All'){
            all = true; 
        }
    }
    
    if(!all){
        List<MapItem> ls = new List<MapItem>();
        for(Integer k=0; k<locs.size(); k++){
        
            for(String ind : AccountTypes){
                if(locs[k].rType=='Account' && ind.equals(locs[k].rAccountStatus)){
                    ls.add(locs[k]);
                    
                }//Are they equal?
               if(locs[k].rType != 'Account'){
                    ls.add(locs[k]);
               }
            }//check for EACH indsutry value.
        }//the list of locations
        locs = ls;  
    }//If we are filtering
}

public void makeMap(){
	if(locs!=null && locs.size()>0){
	    for(MapItem a: locs){
	        locationMap.put(a.rId,a);   
	    }
	}
}
/*
This function goes through the final Filtered list, and makes sure the Starting Point is #1
*/
public void sortLocs(){
     for(Integer k=0; k<locs.size(); k++)
     {  
       //If you find the main account.
       if(locs[k].rId == startingPoint.rId)
       {
           Locs.remove(k);
           break;
       } 
    }
    //If that was the only account found... then you have to add it with different syntax.    
    if(Locs.isEmpty()){
        //startingPoint.rName = 'e:None Returned';
        Locs.add(startingPoint);
    }
    else{Locs.add(0,startingPoint);}
     
} 

public pageReference Search(){
    getLocations();
    return null;
}




public PageReference goBackToRecord(){
    PageReference p;
    if(needFilters){
        p = new PageReference('/'+startingPoint.rId);
    }
    else if (ListAccounts){
        p = new PageReference('/001/o');
    }    
    return p;
}

public Boolean hasPersonAccounts(){
    pAccounts =  MapUtility.hasPersonAccounts(); 
    return pAccounts;
}






/*
    Set the Account Type Options from the UI
*/
public void setAccountTypeOptions(){
   	AccountTypeOptions.add(new selectOption('All','All'));
    AccountTypeOptions.add(new selectOption('New','New'));
    AccountTypeOptions.add(new selectOption('Due Visit','Due Visit'));
    AccountTypeOptions.add(new selectOption('Visit Not Due','Visit Not Due'));
    AccountTypeOptions.add(new selectOption('Dont Visit','Dont Visit'));
}

/*
    get the list of all Account Types
*/ 
public List<SelectOption> getAccountTypeOptions(){
   if(AccountTypeOptions == null){
        setAccountTypeOptions();
   }
     
   return AccountTypeOptions;
}


/*
    Get the list of all Account Industries. 
*/
public List<SelectOption> getAccountIndustryOptions(){
   if(AccountIndustryOptions == null){
        setAccountIndustryOptions();
   }
   return AccountIndustryOptions;
}

/*
    Creates the list of all Account Industries. 
*/
public void setAccountIndustryOptions(){
    Schema.DescribeFieldResult F = Account.Industry.getDescribe();
    List<Schema.PicklistEntry> P = F.getPicklistValues();

    AccountIndustryOptions.add(new SelectOption('All','All'));

    for(integer k =0; k< P.size(); k++)
    {
        if(P[k].isActive())
        {
           AccountIndustryOptions.add(new SelectOption(P[k].getLabel(),P[k].getLabel()));
        }
    }
        
}

/* 
    Creates drop down of Distances 
*/  
public List<SelectOption> getDistances(){ 
    List<SelectOption> distances = new List<SelectOption>{new SelectOption('1','1'),
            new SelectOption('5','5'),new SelectOption('10','10'), new SelectOption('15','15'),
            new SelectOption('20','20'), new SelectOption('25','25'), new SelectOption('50','50'), new SelectOption('75','75'),
            new SelectOption('100','100'),new SelectOption('150','150')
    }; 
  return distances;
}


/*
    returns the number of locations on the map
*/
public Integer getCount(){
    if(locs == null)
    {
        getLocations();
    }
    return locs.size();
}

    
}