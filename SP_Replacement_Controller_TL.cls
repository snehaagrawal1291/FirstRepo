global class SP_Replacement_Controller_TL{

  //Used to get list of Dealer
    public Datetime myDatetime ;
    public String myDatetimeStr {get;set;}
    public String loggedInUserId    {get;set;}
    public String loggedInUserTerritory  {get;set;}
    public String tlLabel = System.Label.TL_Role; 
    public String tldLabel = System.Label.TLD_Role; 
    String rmLabel  = System.Label.RM_Role; 
    
    public Integer fromDay{get;set;}
    public Integer toDay{get;set;}
    public Integer parFromDay{get;set;}
    public Integer parToDay  {get;set;}
    
    public Date todayDate{get;set;}                      
    public ACW__c AcwRecord = new ACW__c() ;
    public ACW__c AcwRecordParent = new ACW__c() ;
       
    list<UserTerritory2Association> userTerrCode;
    list<Territory2> userTerritory;
    String tlPageName  = System.Label.Sales_Planning_TL;
    String AcwLockedRecTypeLabel        = System.Label.Locking;
    String rmPageName = System.Label.Sales_Planning_RM;
    list<Locking_Screen__c> rmalreadyLocked ;
    
    public boolean submitted {get;set;}
    
    global SP_Replacement_Controller_TL(){ 
         todayDate                     = system.today(); 
         Date d                        = system.today();
         myDatetime                    = Datetime.now();         
         userTerrCode                  = new list<UserTerritory2Association>();
         userTerritory                 = new list<Territory2>();
         rmalreadyLocked               = new list<Locking_Screen__c>();         
         myDatetimeStr                 = myDatetime.format('MMMM, yyyy');       
         submitted                     = false;
         User rmUser ;
         
         loggedInUserId=ApexPages.currentPage().getParameters().get('id');
         
         if(loggedInUserId=='' || loggedInUserId==null ){
            loggedInUserId=UserInfo.getUserId();
         }
         
         userTerrCode=[select territory2Id,id from UserTerritory2Association where UserId=:loggedInUserId AND (RoleInTerritory2=: tlLabel OR RoleInTerritory2=: tldLabel) limit 1];  
         if(userTerrCode.size() > 0){
             userTerritory=[select name,ParentTerritory2Id, id from Territory2 where id=:userTerrCode[0].Territory2Id];
             Territory2 rmTerr=  [Select id,name from Territory2 where id =:userTerritory[0].ParentTerritory2Id];
             UserTerritory2Association regionForRM = [Select RoleInTerritory2,Territory2Id,Territory2.name,UserId,User.name,ID from UserTerritory2Association where Territory2Id =:rmTerr.id and RoleInTerritory2=: rmLabel limit 1];
             rmUser=  [select name,id,email from User where id=:regionForRM.UserId];
         }         
         if(userTerritory.size() > 0){
             loggedInUserTerritory=userTerritory[0].Name;
         } 
         try{            
             Id acwLockedRecTypeId    = [select id,DeveloperName from RecordType where SobjectType='ACW__c' and DeveloperName =: AcwLockedRecTypeLabel Limit 1].Id;
            
             //Querying ACW record for current/TL page     
             AcwRecord       = [Select Page__c,Sales_Planning__c,Parent_ACW__c,From_Date__c,To_Date__c,RecordTypeId from ACW__c where RecordTypeId=:acwLockedRecTypeId  AND Page__c=:tlPageName AND Sales_Planning__c=true AND Month__c =:Integer.valueof(d.month()) AND Year__c=:String.valueof(d.year()) limit 1];
             AcwRecordParent = [Select Page__c,Sales_Planning__c,From_Date__c,To_Date__c,RecordTypeId from ACW__c where RecordTypeId=:acwLockedRecTypeId  AND Page__c=:rmPageName AND Sales_Planning__c=true AND Month__c =:Integer.valueof(d.month()) AND Year__c=:String.valueof(d.year()) limit 1];
             
             date fromDate = AcwRecordParent.From_Date__c;
             parFromDay = fromDate.day();
             
             date toDate = AcwRecordParent.To_Date__c;
             parToDay = toDate.day();
             
             date fDate = AcwRecord.From_Date__c;
             fromDay = fDate.day();
             
             date tDate = AcwRecord.To_Date__c;
             toDay = tDate.day();
            
             //Querying Rm Locking_Screen record
             rmalreadyLocked = [SELECT id,name,Submitted__c,Month__c,User__c,Year__c from Locking_Screen__c WHERE User__c =:rmUser.Id AND Month__c =: String.valueOf(d.month()) AND Year__c =: String.valueOf(d.year()) AND Submitted__c = true AND status__c='Submitted'];
             if(rmalreadyLocked.size()>0){
                submitted = true;
             }
         }
         catch(Exception e){
            system.debug('--exception--'+e);
         }   
           
    }
    @RemoteAction
    Public Static String getAcwRecords(String loggedInUserId) {  
            
             return null;
    }
    @RemoteAction
    Public Static List<SPHandlerFor_SP_Replacement_ControllerTL.DealerWrapper> getDealersOfTL(String loggedInUserId) {  
            
            SPHandlerFor_SP_Replacement_ControllerTL handler = new SPHandlerFor_SP_Replacement_ControllerTL();  
            return handler.getTLWiseSalesPlanningRecords(loggedInUserId);
    }
    @RemoteAction
    Public Static void updateDlSpRecord (Map<String,String> mapOfSalesPlanning,String loggedInUserId) {
             Date d                        = system.today();
             String month                  = String.valueOf(d.month());
             String year                   = String.valueOf(d.Year());
             Datetime myDatetime           = Datetime.now();
             String myDatetimeStr          = myDatetime.format('MMMM, yyyy');
             String loggedInUserTerritory;
             
             String repTLLabel             = System.Label.Replacement_TL;
             String repROLabel             = System.Label.Replacement_RO;
             String repDealerLabel         = System.Label.Replacement_Dealer;
             String tlLabel                = System.Label.TL_Role;
             String tldLabel               = System.Label.TLD_Role;
             String rmLabel                = System.Label.RM_Role; 
             
             Set<String> salesPlanningDLId = new Set<String>();
             Set<String> setOfParentSP     = new Set<String>();
             
             Map<String,String> mapOfDLIDAndPlanned            = new Map<String,String>();
             Map<String,String> mapOfCatAndCatCode             = new map<String,String>();
             Map<String,id> mapOfExternalIdandID               = new Map<String,id>();
             Map<String,String> mapOfcustNumAndTerrCode             = new map<String,String>();
             Map<String,String> mapOfcustNumAndRegCode               = new Map<String,String>();
             Map<String,String> mapOfCatCodeAndCatName        = new map<String,String>();
              
             List<Territory2> parentRegCode                    =new List<Territory2>();
             List<Territory2> parentRegId                      =new List<Territory2>();
             List<String> parentRegIdList                      =new List<String>();
             List<String> parentRegCodeList                    =new List<String>();
             list<String> parentZoneCodeList                   = new List<String>();
             list<String> parentZoneCodeList1                  = new List<String>();
             List<Sales_Planning__c> listOfSalesPlanningDL     = new List<Sales_Planning__c>();
             List<Sales_Planning__c> upsertsalesPlanningDLList = new List<Sales_Planning__c>();
             List<Sales_Planning__c> salesPlanningTL           = new List<Sales_Planning__c>();
             List<Sales_Planning__c> listOfSalesPlanningDLForInsert = new List<Sales_Planning__c>();
             List<Sales_Planning__c> listOfTLSP                = new list<Sales_Planning__c>();
             List<Account> accList                             = new list<Account>();
             List<UserTerritory2Association> regionForTL            = new List<UserTerritory2Association>();
             List<UserTerritory2Association> regionForRM            = new List<UserTerritory2Association>();
             List<Locking_Screen__c> alreadyLocked                  = new list<Locking_Screen__c>(); 
             List<Territory2> listOfTerr                            = new List<Territory2>();
             List<Territory2> tlTerritory                           = new List<Territory2>();
             List<Territory2> rmTerritory                           = new List<Territory2>();
             list<Territory2> parentZoneCode                        = new list<Territory2>();
             Set<String> regionCode                     = new Set<String>();
             Set<Id> regionId                           = new Set<Id>();
             
             Server_Url__c serverUrl;
             Sales_Planning__c spDLRecord;
             Sales_Planning__c salesPlanning;             
             Account acc;
            
             Id replaceTLId = [select id,DeveloperName from RecordType where SobjectType='Sales_Planning__c' and DeveloperName =: repTLLabel Limit 1].Id;
             Id replaceROId = [select id,DeveloperName from RecordType where SobjectType='Sales_Planning__c' and DeveloperName =: repROLabel Limit 1].Id;
             Id replaceDealerId  = [select id,DeveloperName from RecordType where SobjectType='Sales_Planning__c' and DeveloperName =: repDealerLabel Limit 1].Id;
             
             /*if(loggedInUserId==null || loggedInUserId==''){
                loggedInUserId=UserInfo.getUserId();
             }*/
            regionForTL = [Select IsActive,RoleInTerritory2,Territory2Id,Territory2.name,UserId,User.name,ID from UserTerritory2Association where UserId =:loggedInUserId AND  (RoleInTerritory2=: tlLabel OR RoleInTerritory2=: tldLabel)];
            //system.debug('-----------regionForTL in controller'+regionForTL);
             for(UserTerritory2Association reg : regionForTL){
                regionId.add(reg.Territory2Id);
                regionCode.add(reg.Territory2.name);                
             } 
             parentRegId=[select ParentTerritory2Id,id,name from Territory2 where Id IN : regionId ];
             for(Territory2 id:parentRegId){
               parentRegIdList.add(id.ParentTerritory2Id);
             }
             parentRegCode=[select id,name,ParentTerritory2Id from Territory2 where id In : parentRegIdList];
             for(Territory2 code:parentRegCode){
                parentRegCodeList.add(code.name);
                parentZoneCodeList.add(code.ParentTerritory2Id);
              }  
               parentZoneCode=[select id,name,ParentTerritory2Id from Territory2 where id In : parentZoneCodeList];
                for(Territory2 code:parentZoneCode){
                parentZoneCodeList1.add(code.name);
                //parentZoneCodeList.add(code.ParentTerritory2Id);
              }  
             //Getting RM of loggedin TL to send email notification by submitting the sales plan
             tlTerritory=  [Select ParentTerritory2Id,id,name from Territory2 where Id IN : regionId];
             rmTerritory=  [Select id,name from Territory2 where id =:tlTerritory[0].ParentTerritory2Id];
             regionForRM = [Select RoleInTerritory2,Territory2Id,Territory2.name,UserId,User.name,ID from UserTerritory2Association where Territory2Id =:rmTerritory[0].id and RoleInTerritory2=: rmLabel ];
             User rmUser=  [select name,id,email from User where id=:regionForRM[0].UserId];
             
             loggedInUserTerritory = tlTerritory[0].name;
             salesPlanningTL = [SELECT Id,name,ASP__c,Budget__c,Dealer__c,RecordTypeId,Category__c,SYS_TL_CAT__c,Category_Description__c,Dealer_CustNumber__c,Dealer_Name__c,L3M__c,LYCM__c,Month__c,Region_code__c,Region_Description__c,Target_Quantity__c,Territory_Code__c,Year__c FROM Sales_Planning__c WHERE Region_code__c IN:regionCode AND Year__c =:year AND Month__c =:month AND RecordTypeId =: replaceROId ];
             
             accList=[select id,KUNNR__c,Sales_District_Text__c,Region_Code__c,name from Account where Active__c=true];
             for(Account ac:accList){
                mapOfcustNumAndTerrCode.put(ac.KUNNR__c,ac.Sales_District_Text__c);//dlnumber and terr Code
                mapOfcustNumAndRegCode.put(ac.KUNNR__c,ac.Region_Code__c);//region code
             }
             //for(Sales_Planning__c temp :salesPlanningTL){
                  //   mapOfCatAndCatCode.put(temp.Category__c,temp.Category_Description__c);  
             //} 
             for(Sales_Planning_Categories__c spc :[Select Name, Category_Code__c, Include_in_Sales_Planning__c, Sort_Order__c from Sales_Planning_Categories__c where Include_in_Sales_Planning__c = true]) {
              
               mapOfCatCodeAndCatName.put(spc.Category_Code__c,spc.Name);                            
             }         
             for(String temp : mapOfSalesPlanning.keySet()){
                    String key = temp;
                    String st = '';
                    String parentSP = '';     
                                   
                    String[] listKey = key.split('@@');                   
                    if(listKey[0] != 'undefined'){
                            salesPlanningDLId.add(listKey[0]);
                            mapOfDLIDAndPlanned.put(listKey[0],mapOfSalesPlanning.get(temp));
                    }
                    else{
                            st = listKey[6] + listKey[2] + listKey[3] + listKey[4] + month + year ;//dlNumber + catname+ terrcode + m + y
                            system.debug('-------------------key'+key); 
                            parentSP = listKey[3] + listKey[4] + month + year;
                            salesPlanning = new Sales_Planning__c(SPExternalIDTL__c = parentSP );
                            setOfParentSP.add(parentSP);    
                            acc = new account(KUNNR__c = listKey[1]);
                            spDLRecord = new Sales_Planning__c(Dealer_CustNumber__c = listKey[1],Dealer__c = listKey[6] ,SYS_USED_IN_CODE__c = parentSP ,Category__c =listKey[4],Category_Description__c = mapOfCatCodeAndCatName.get(listKey[4]),
                            Month__c = month ,Year__c = year ,Region_code__c = parentRegCodeList[0],Dealer_Name__c= listKey[5],Value__c=Decimal.valueOf(listKey[7]),
                            RecordTypeId = replaceDealerId ,Territory_Code__c = listKey[3],Total_planned__c = Decimal.valueOf(mapOfSalesPlanning.get(temp)),SPExternalIDTL__c = st);
                            
                            listOfSalesPlanningDLForInsert.add(spDLRecord );
                    }
             }
             if(setOfParentSP.size() > 0){
                            listOfTLSP = [SELECT Id,SPExternalIDTL__c,RecordTypeId,Category__c,Category_Description__c,Month__c,Region_code__c,Territory_Code__c,Year__c FROM Sales_Planning__c WHERE RecordTypeId =: replaceTLId AND SPExternalIDTL__c IN:setOfParentSP];
             }
           
             if(salesPlanningDLId.size() > 0){
                 listOfSalesPlanningDL = [SELECT id,SPExternalIDTL__c,Total_planned__c from Sales_Planning__c WHERE SPExternalIDTL__c IN: salesPlanningDLId];
             }
             if(listOfTLSP.size() > 0){
                 for(Sales_Planning__c temp: listOfTLSP){
                         mapOfExternalIdandID.put(temp.SPExternalIDTL__c,temp.id);
                 }
             }            
           
            if(listOfSalesPlanningDL.size() > 0){
                    for(Sales_Planning__c sp : listOfSalesPlanningDL){
                            String val = mapOfDLIDAndPlanned.get(sp.SPExternalIDTL__c);
                            sp.Total_planned__c = Decimal.valueOf(val);
                            upsertsalesPlanningDLList.add(sp);
                    }
            }
            
            if(upsertsalesPlanningDLList.size() > 0){
                    upsert upsertsalesPlanningDLList SPExternalIDTL__c;
            }
            if(listOfSalesPlanningDLForInsert.size() > 0){
                    for(Sales_Planning__c  temp:listOfSalesPlanningDLForInsert){
                                    temp.Parent_Sales_Planning__c = mapOfExternalIdandID.get(temp.SYS_USED_IN_CODE__c);
                    }
                    upsert listOfSalesPlanningDLForInsert SPExternalIDTL__c;
            }
            alreadyLocked = [SELECT id,name,Submitted__c,Month__c,User__c,Year__c from Locking_Screen__c WHERE User__c =:loggedInUserId AND Month__c =: month AND Year__c =: year AND Submitted__c = true AND (status__c='Rejected' OR status__c='Submitted')];
            if(!(alreadyLocked.size() > 0)){
                Locking_Screen__c lsforTL= new Locking_Screen__c(User__c =loggedInUserId,Month__c = month ,Year__c = year,Submitted__c = true,Status__c='Submitted',Territory_Code__c=loggedInUserTerritory,View_Sales_Planning__c='/apex/SP_Replacement_TL?id='+loggedInUserId);
                insert lsforTL;
            }else{
                 alreadyLocked[0].Status__c = 'Submitted';
                 update alreadyLocked;
            }
            
            Id lockRecId=[select id from Locking_Screen__c where User__c =:loggedInUserId AND Month__c =:month AND Year__c =: year AND Submitted__c = true].Id;
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval...');
            req1.setObjectId(lockRecId);
           
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req1.setNextApproverIds(new Id[] {rmUser.Id});
            Approval.ProcessResult result = Approval.process(req1);         
            
            serverUrl=[select url__c from Server_Url__c limit 1];
            FeedItem fitem=new FeedItem();
            fItem.parentId=rmUser.Id;
            fItem.Title='Click here to Approve/Reject';
            fItem.body = 'Sales planning has been submitted for the month '+myDatetimeStr+' by Territory Lead of '+loggedInUserTerritory+'. ';
            fItem.LinkUrl = serverUrl.url__c+'/apex/SP_Replacement_TL?id='+loggedInUserId;
            insert fItem;
            
            /*
            Messaging.SingleEmailMessage mailHandler =new Messaging.SingleEmailMessage();
            String name=UserInfo.getName(); 
            String[] mail=new String[]{'sneha.agrawal@extentor.com'};//rmUser.email
            String Body = 'Sales planning has been submitted for the month '+month+' by Territory Lead '+UserInfo.getName()+'.<br><br>';
            body+='To get details click on link <br><br>';
            body+='<a href="https://c.cs5.visual.force.com/apex/SP_Replacement_TL?id='+loggedInUserId+'">View the sales Planning Details for TL '+name+'</a><br><br>';
            body+='<br>For Approve or Reject TL Sales Planning, Please click the below link<br><br>';
            body+='<a href="https://cs5.salesforce.com/'+lockRecId+'">Approve/Reject Sales planning </a><br><br>';
            body+='Regards,'+'<br><br>';
            body+='Territory Lead<br>'+name;                      
            //mail=UserInfo.getUserEmail();
            mailHandler.setToAddresses(mail);
            mailHandler.setHtmlBody (body);
            mailHandler.setReplyTo(UserInfo.getUserEmail());
            mailHandler.setSubject('Sales planning has been submitted for the month '+month);
            try{
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mailHandler});
            }
            catch(Exception e){
            }
            system.debug('-------To-mail address'+mail);
                
                        Messaging.SingleEmailMessage mailHandler = new Messaging.SingleEmailMessage(); 
                        EmailTemplate emailTemp=new EmailTemplate ();
                        emailTemp=[SELECT id,Name FROM EmailTemplate where name = 'Sales planning submission notification' limit 1];
                        mailHandler.setTargetObjectId(loggedInUserId);                      
                        mailHandler.setSenderDisplayName('Sneha');
                        mailHandler.setReplyTo('Sneha.agrawal@extentor.com');
                        //mailHandler.setWhatId(UserInfo.getUserId());
                        mailHandler.saveAsActivity = false;
                        mailHandler.setTemplateId(emailTemp.id);
                        system.debug('mailHandler'+mailHandler);
                        try{
                        Messaging.sendEmail(new Messaging.Email[] { mailHandler }); 
                        }
                        catch(Exception e){
                        
                        } */
                                     
    }
     @RemoteAction
    Public Static void saveAsDraftDlSpRecord (Map<String,String> mapOfSalesPlanning,String loggedInUserId) {
             Date d                        = system.today();
             String month                  = String.valueOf(d.month());
             String year                   = String.valueOf(d.Year());
             String repTLLabel             = System.Label.Replacement_TL;
             String repROLabel             = System.Label.Replacement_RO;
             String repDealerLabel         = System.Label.Replacement_Dealer;
             String tlLabel                = System.Label.TL_Role;
             String rmLabel                = System.Label.RM_Role; 
             String tldLabel               = System.Label.TLD_Role; 
             //loggedInUserId=ApexPages.currentPage().getParameters().get('id');
             
             Set<String> salesPlanningDLId = new Set<String>();
             Set<String> setOfParentSP     = new Set<String>();
             
             Map<String,String> mapOfCatCodeAndCatName        = new map<String,String>();
             Map<String,String> mapOfDLIDAndPlanned            = new Map<String,String>();
             Map<String,String> mapOfCatAndCatCode             = new map<String,String>();
             Map<String,id> mapOfExternalIdandID               = new Map<String,id>();
             Map<String,String> mapOfcustNumAndTerrCode             = new map<String,String>();
             Map<String,String> mapOfcustNumAndRegCode               = new Map<String,String>();
             
             List<Territory2> parentRegCode                    =new List<Territory2>();
             List<Territory2> parentRegId                      =new List<Territory2>();
             List<String> parentRegIdList                      =new List<String>();
             List<String> parentRegCodeList                    =new List<String>();
             list<String> parentZoneCodeList                   = new List<String>();
             list<String> parentZoneCodeList1                  = new List<String>();
             List<Sales_Planning__c> listOfSalesPlanningDL     = new List<Sales_Planning__c>();
             List<Sales_Planning__c> upsertsalesPlanningDLList = new List<Sales_Planning__c>();
             List<Sales_Planning__c> salesPlanningTL           = new List<Sales_Planning__c>();
             List<Sales_Planning__c> listOfSalesPlanningDLForInsert = new List<Sales_Planning__c>();
             List<Sales_Planning__c> listOfTLSP                = new list<Sales_Planning__c>();
             List<Account> accList                             = new list<Account>();
             List<UserTerritory2Association> regionForTL            = new List<UserTerritory2Association>();
             List<UserTerritory2Association> regionForRM            = new List<UserTerritory2Association>();
             List<Locking_Screen__c> alreadyLocked                  = new list<Locking_Screen__c>(); 
             List<Territory2> listOfTerr                            = new List<Territory2>();
             List<Territory2> tlTerritory                           = new List<Territory2>();
             List<Territory2> rmTerritory                           = new List<Territory2>();
             list<Territory2> parentZoneCode                        = new list<Territory2>();
             Set<String> regionCode                     = new Set<String>();
             Set<Id> regionId                           = new Set<Id>();
             
             Sales_Planning__c spDLRecord;
             Sales_Planning__c salesPlanning;             
             Account acc;
            
             Id replaceTLId = [select id,DeveloperName from RecordType where SobjectType='Sales_Planning__c' and DeveloperName =: repTLLabel Limit 1].Id;
             Id replaceROId = [select id,DeveloperName from RecordType where SobjectType='Sales_Planning__c' and DeveloperName =: repROLabel Limit 1].Id;
             Id replaceDealerId  = [select id,DeveloperName from RecordType where SobjectType='Sales_Planning__c' and DeveloperName =: repDealerLabel Limit 1].Id;
             
             /*if(loggedInUserId==null || loggedInUserId==''){
                loggedInUserId=UserInfo.getUserId();
             }*/
            regionForTL = [Select IsActive,RoleInTerritory2,Territory2Id,Territory2.name,UserId,User.name,ID from UserTerritory2Association where UserId =:loggedInUserId and  (RoleInTerritory2=: tlLabel OR RoleInTerritory2=: tldLabel)];
            //system.debug('-----------regionForTL in controller'+regionForTL);
             for(UserTerritory2Association reg : regionForTL){
                regionId.add(reg.Territory2Id);
                regionCode.add(reg.Territory2.name);                
             } 
             parentRegId=[select ParentTerritory2Id,id,name from Territory2 where Id IN : regionId ];
             for(Territory2 id:parentRegId){
               parentRegIdList.add(id.ParentTerritory2Id);
             }
             parentRegCode=[select id,name,ParentTerritory2Id from Territory2 where id In : parentRegIdList];
             for(Territory2 code:parentRegCode){
                parentRegCodeList.add(code.name);
                parentZoneCodeList.add(code.ParentTerritory2Id);
              }  
             parentZoneCode=[select id,name,ParentTerritory2Id from Territory2 where id In : parentZoneCodeList];
              for(Territory2 code:parentZoneCode){
                parentZoneCodeList1.add(code.name);
                //parentZoneCodeList.add(code.ParentTerritory2Id);
              }  
             //Getting RM of loggedin TL to send email notification by submitting the sales plan
             tlTerritory=  [Select ParentTerritory2Id,id,name from Territory2 where Id IN : regionId];
             rmTerritory=  [Select id,name from Territory2 where id =:tlTerritory[0].ParentTerritory2Id];
             regionForRM = [Select RoleInTerritory2,Territory2Id,Territory2.name,UserId,User.name,ID from UserTerritory2Association where Territory2Id =:rmTerritory[0].id and RoleInTerritory2=: rmLabel ];
             User rmUser=  [select name,id,email from User where id=:regionForRM[0].UserId];
             
             salesPlanningTL = [SELECT Id,name,ASP__c,Budget__c,Dealer__c,RecordTypeId,Category__c,SYS_TL_CAT__c,Category_Description__c,Dealer_CustNumber__c,Dealer_Name__c,L3M__c,LYCM__c,Month__c,Region_code__c,Region_Description__c,Target_Quantity__c,Territory_Code__c,Year__c FROM Sales_Planning__c WHERE Region_code__c IN:regionCode AND Year__c =:year AND Month__c =:month AND RecordTypeId =: replaceROId ];
             
             accList=[select id,KUNNR__c,Sales_District_Text__c,Region_Code__c,name from Account where Active__c=true];
             for(Account ac:accList){
                mapOfcustNumAndTerrCode.put(ac.KUNNR__c,ac.Sales_District_Text__c);//dlnumber and terr Code
                mapOfcustNumAndRegCode.put(ac.KUNNR__c,ac.Region_Code__c);//region code
             }
             //for(Sales_Planning__c temp :salesPlanningTL){
                //     mapOfCatAndCatCode.put(temp.Category__c,temp.Category_Description__c);  
             //} 
             for(Sales_Planning_Categories__c spc :[Select Name, Category_Code__c, Include_in_Sales_Planning__c, Sort_Order__c from Sales_Planning_Categories__c where Include_in_Sales_Planning__c = true]) {
              
               mapOfCatCodeAndCatName.put(spc.Category_Code__c,spc.Name);                            
            }           
             for(String temp : mapOfSalesPlanning.keySet()){
                    String key = temp;
                    String st = '';
                    String parentSP = '';   
                    system.debug('-------------------key'+key);                
                    String[] listKey = key.split('@@');                   
                    if(listKey[0] != 'undefined'){
                            salesPlanningDLId.add(listKey[0]);
                            mapOfDLIDAndPlanned.put(listKey[0],mapOfSalesPlanning.get(temp));
                    }
                    else{
                            st = listKey[6] + listKey[2] + listKey[3] + listKey[4] + month + year ;//accid regCode terrcode  catCode + m + y
                            system.debug('st-------------'+st);
                            system.debug('mapOfCatAndCatCode-------------'+mapOfCatAndCatCode.get(listKey[4]));
                            parentSP = listKey[3] + listKey[4] + month + year;
                            salesPlanning = new Sales_Planning__c(SPExternalIDTL__c = parentSP );
                            setOfParentSP.add(parentSP);    
                            acc = new account(KUNNR__c = listKey[1]);
                            spDLRecord = new Sales_Planning__c(Dealer_CustNumber__c = listKey[1],Dealer__c = listKey[6] ,SYS_USED_IN_CODE__c = parentSP ,Category__c =listKey[4],Category_Description__c = mapOfCatCodeAndCatName.get(listKey[4]),
                            Month__c = month ,Year__c = year ,Zone__c = parentZoneCodeList1[0],Region_code__c = parentRegCodeList[0],Dealer_Name__c= listKey[5],Value__c=Decimal.valueOf(listKey[7]),
                            RecordTypeId = replaceDealerId ,Territory_Code__c = listKey[3],Total_planned__c = Decimal.valueOf(mapOfSalesPlanning.get(temp)),SPExternalIDTL__c = st);
                            
                            listOfSalesPlanningDLForInsert.add(spDLRecord );
                    }
             }
             if(setOfParentSP.size() > 0){
                            listOfTLSP = [SELECT Id,SPExternalIDTL__c,RecordTypeId,Category__c,Category_Description__c,Month__c,Region_code__c,Territory_Code__c,Year__c FROM Sales_Planning__c WHERE RecordTypeId =: replaceTLId AND SPExternalIDTL__c IN:setOfParentSP];
             }
           
             if(salesPlanningDLId.size() > 0){
                 listOfSalesPlanningDL = [SELECT id,SPExternalIDTL__c,Total_planned__c from Sales_Planning__c WHERE SPExternalIDTL__c IN: salesPlanningDLId];
             }
             if(listOfTLSP.size() > 0){
                 for(Sales_Planning__c temp: listOfTLSP){
                         mapOfExternalIdandID.put(temp.SPExternalIDTL__c,temp.id);
                 }
             }            
           
            if(listOfSalesPlanningDL.size() > 0){
                    for(Sales_Planning__c sp : listOfSalesPlanningDL){
                            String val = mapOfDLIDAndPlanned.get(sp.SPExternalIDTL__c);
                            sp.Total_planned__c = Decimal.valueOf(val);
                            upsertsalesPlanningDLList.add(sp);
                    }
            }
            if(upsertsalesPlanningDLList.size() > 0){
                    upsert upsertsalesPlanningDLList SPExternalIDTL__c;
            }
            if(listOfSalesPlanningDLForInsert.size() > 0){
                    for(Sales_Planning__c  temp:listOfSalesPlanningDLForInsert){
                                    temp.Parent_Sales_Planning__c = mapOfExternalIdandID.get(temp.SYS_USED_IN_CODE__c);
                    }
                    upsert listOfSalesPlanningDLForInsert SPExternalIDTL__c;
            }
    }
}