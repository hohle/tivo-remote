//
//  CFBonjour.m
//  murmur
//
//  Created by ecume des jours on 10/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CFBonjour.h"

#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>


NSMutableArray * foundBonjourClients;

static CFNetServiceBrowserRef 	gServiceBrowserRef = NULL;
static void MyBrowseCallBack(CFNetServiceBrowserRef, CFOptionFlags, CFTypeRef, CFStreamError *, void *);
static void	MyBrowserCallback(CFNetServiceBrowserRef browser, CFOptionFlags flags, CFTypeRef domainOrService, CFStreamError* error, void* info);
static void MyResolveCallback(CFNetServiceRef, CFStreamError *, void *);
static CFMutableArrayRef		gCFServiceArrayRef;
static CFMutableDictionaryRef 	gServiceDictionary;


CFStringRef gServiceType;
UInt16 gPortNumber;
CFStringRef gTextRecord;

static CFNetServiceRef			gRegisteredService = NULL;
static CFNetServiceRef			gServiceBeingResolved = NULL;

typedef struct{
    int refCount;
    char name[64];
    char type[256];
    char domain[256];
} MyService;
        



@implementation CFBonjour

- (id)init
{
//NSLog(@"starting bonjour services");
return self;
}

void netServiceClientCallback(CFNetServiceRef service, CFStreamError *error, void *info)
{
    // handle netservice events...
	//NSLog(@"netservice event callback");
}


// bonjour



static OSStatus
MyStartBrowsingForServices(CFStringRef type, CFStringRef domain)
{

foundBonjourClients = [[NSMutableArray array]retain];


    CFNetServiceClientContext clientContext = { 0, NULL, NULL, NULL, NULL };
    CFStreamError	error;
    Boolean			result;
    OSStatus		err = noErr;

    assert(type != NULL);
    assert(domain != NULL);
	
	// Instantiate Net Services Browser. 
    gServiceBrowserRef = CFNetServiceBrowserCreate(kCFAllocatorDefault, MyBrowserCallback, &clientContext);
    if (gServiceBrowserRef == NULL)
        err = memFullErr;
    else
    {
		// Schedule run loop for service acquisition.
        CFNetServiceBrowserScheduleWithRunLoop(gServiceBrowserRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// Scheduling search for services.
        result = CFNetServiceBrowserSearchForServices(gServiceBrowserRef, domain, type, &error);
        
        if (result == FALSE)
        {
            // Something went wrong so lets clean up.
            CFNetServiceBrowserUnscheduleFromRunLoop(gServiceBrowserRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            CFRelease(gServiceBrowserRef);
            gServiceBrowserRef = NULL;
			
			//NSLog(@"bonjour browser error");
            fprintf(stderr, "CFNetServiceBrowserSearchForServices returned (domain = %d, error = %ld)\n", error.domain, error.error);
            err = error.error;
        }
		else {
		//NSLog(@"bonjour browser started");
		}
    }

    return err;
}



static void
MyResolveService(CFStringRef name, CFStringRef type, CFStringRef domain)
{
	
    CFNetServiceClientContext context = { 0, NULL, NULL, NULL, NULL };
    CFStreamError error;
    
    assert(name   != NULL);
    assert(type   != NULL);
    assert(domain != NULL);
        
    if (gServiceBeingResolved) {
        
        //fprintf(stderr, "Resolve canceled\n");
		//MyCancelResolve();
    }
    
    gServiceBeingResolved = CFNetServiceCreate(kCFAllocatorDefault, domain, type, name, 0);
    assert(gServiceBeingResolved != NULL);
    
    CFNetServiceSetClient(gServiceBeingResolved, MyResolveCallback, &context);
    CFNetServiceScheduleWithRunLoop(gServiceBeingResolved, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    
    if (CFNetServiceResolveWithTimeout(gServiceBeingResolved, 0, &error) == false) {
    
        // Something went wrong so lets clean up.
        CFNetServiceUnscheduleFromRunLoop(gServiceBeingResolved, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFNetServiceSetClient(gServiceBeingResolved, NULL, NULL);
        CFRelease(gServiceBeingResolved);
        gServiceBeingResolved = NULL;
        
        fprintf(stderr, "CFNetServiceResolve returned (domain = %d, error = %ld)\n", error.domain, error.error);
    }
    
    return;
	
	
}

void
MyCancelResolve()
{
    assert(gServiceBeingResolved != NULL);
    
    CFNetServiceUnscheduleFromRunLoop(gServiceBeingResolved, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFNetServiceSetClient(gServiceBeingResolved, NULL, NULL);
    CFNetServiceCancel(gServiceBeingResolved);
    CFRelease(gServiceBeingResolved);
    gServiceBeingResolved = NULL;
    
    return;
}

Boolean
MyCopyFirstIPv4Address(CFNetServiceRef service, CFStringRef * addressString, CFStringRef * portString)
{
    struct sockaddr * socketAddress = NULL;
    CFArrayRef addresses;
    char buffer[256];
    uint16_t port;
    int count;
    Boolean result = false;
    
    assert(service       != NULL);
    assert(addressString != NULL);
    assert(portString    != NULL);
    
    addresses = CFNetServiceGetAddressing(service);
    
    assert(addresses != NULL);
    assert(CFArrayGetCount(addresses) > 0);
    
	/* Search for the first IPv4 address in the array. */
	for (count = 0; count < CFArrayGetCount(addresses); count++) {
	
		socketAddress = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addresses, count));
	
        /* Only continue if this is an IPv4 address. */
        if (socketAddress && socketAddress->sa_family == AF_INET) {
        
            if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer))) {
            
                *addressString = CFStringCreateWithCString(kCFAllocatorDefault, buffer, kCFStringEncodingASCII);
                port = ntohs(((struct sockaddr_in *)socketAddress)->sin_port);
                *portString = CFStringCreateWithFormat(kCFAllocatorDefault, 0, CFSTR("%d"), port);
                result = true;
            }
            break;
        }
    }
    return result;
}



static void
MyResolveCallback(CFNetServiceRef service, CFStreamError* error, void* info)
{

//	NSLog(@"resolve callback");
   
    
    CFStringRef addressString = NULL;
    CFStringRef portString = NULL;
    
    if (MyCopyFirstIPv4Address(service, &addressString, &portString) == true) {
    
        // Cancel the Resolve now that we have an IPv4 address.
      //  MyCancelResolve();

        if (addressString && portString) {
        
			/*
            if (CFEqual(CFNetServiceGetType(service), kMyTypeHTTP)) {
    
    
                CFStringRef txtRecord = CFNetServiceGetProtocolSpecificInformation(service);
                if (txtRecord) {
                    CFDictionaryRef two = MyCreateCFDictionaryFromTXT(txtRecord);
                    CFDictionaryRef txtDictionary;
                    CFStringRef string;
                    assert(two != NULL);
                    
                    string = MyCreateTXTFromCFDictionary(two);
                    txtDictionary = MyCreateCFDictionaryFromTXT(string);
    
                    MyViewWebPageAtLocation(addressString, portString, CFDictionaryGetValue(txtDictionary, kMyPathKey));
                    CFRelease(txtDictionary);
                } else {
                    MyViewWebPageAtLocation(addressString, portString, NULL);
                }
            }
            */
			
		char theAddress[64];   
		char thePort[64];
		char theServiceName[256];
		
		CFStringGetCString(addressString,   theAddress,    64, kCFStringEncodingUTF8);
		CFStringGetCString(portString,   thePort,   64, kCFStringEncodingUTF8);
		CFStringGetCString(CFNetServiceGetName (service),   theServiceName,    256, kCFStringEncodingUTF8);



		//NSLog(@"resolved: %@ on port %@ for %@\n",[NSString stringWithCString:theAddress encoding:4], [NSString stringWithCString:thePort encoding:4], [NSString stringWithCString:theServiceName encoding:4]);
		
		NSString * objectToAdd = [NSString stringWithCString:theAddress encoding:4];
		NSDictionary * theBonjourDictionaryToAdd = [NSDictionary dictionaryWithObjectsAndKeys:objectToAdd,@"resolvedIP",[NSString stringWithCString:theServiceName encoding:4],@"serviceName",[NSString stringWithCString:thePort encoding:4],@"port",nil];

		//add the bonjour client to our mutable array
				
		if(![foundBonjourClients containsObject:theBonjourDictionaryToAdd])
		[foundBonjourClients addObject:theBonjourDictionaryToAdd];

		//NSLog(@"total bonjour clients: %i",[foundBonjourClients count]);
		
		[[NSNotificationCenter defaultCenter] 
		postNotification:[NSNotification 
			notificationWithName:@"bonjourClientAdded" 
						  object:nil 
						userInfo:theBonjourDictionaryToAdd]];
		
		
		}
    }
    
    if (addressString) CFRelease(addressString);
    if (portString) CFRelease(portString);
    
    return;
	
	
	
}



static void
MyBrowserCallback(CFNetServiceBrowserRef browser, CFOptionFlags flags, CFTypeRef domainOrService, CFStreamError* error, void* info)
{        

	//define the struct that will hold info about this service
	
	/*
	typedef struct{
    int refCount;
    char name[64];
    char type[256];
    char domain[256];
	} MyService;
*/
	
	
    if (flags & kCFNetServiceFlagRemove){			//service needs to be removed
		//NSLog(@"removing a service");	
       // MyRemoveService((CFNetServiceRef)domainOrService, flags);
	   
	     CFStringRef hostName;
		MyService * theService;

		assert(domainOrService != NULL);

		theService = malloc(sizeof(MyService));
		assert(theService != NULL);
	
		CFStringGetCString(CFNetServiceGetName(domainOrService),   theService->name,    64, kCFStringEncodingUTF8);
		CFStringGetCString(CFNetServiceGetType(domainOrService),   theService->type,   256, kCFStringEncodingUTF8);
		CFStringGetCString(CFNetServiceGetDomain(domainOrService), theService->domain, 256, kCFStringEncodingUTF8);

		//cycle through our found services until we find one whose name matches the one we want to remove
		NSEnumerator* myEnum = [foundBonjourClients objectEnumerator];
		NSDictionary * currentService;
		NSString * stringToCheck = [NSString stringWithCString:(theService->name) encoding:4];
	
		while (currentService = [myEnum nextObject]) {
		
			//NSLog(@"checking %@ against %@",[currentService objectForKey:@"serviceName"], stringToCheck);
		
			if ([[currentService objectForKey:@"serviceName"]  isEqualToString:stringToCheck]){
			
			NSDictionary * theOneToRemove = [NSDictionary dictionaryWithDictionary:currentService];
			
			[foundBonjourClients removeObject:currentService];
			
			//NSLog(@"removing: %@\n",stringToCheck);
			
			[[NSNotificationCenter defaultCenter] 
				postNotification:[NSNotification 
				notificationWithName:@"bonjourClientRemoved" 
				object:nil 
				userInfo:theOneToRemove]];
			
			
			}
		}
		
	 
	
	}

    else {			//new service found - add it

//	NSLog(@"adding service\n");
		
    CFStringRef hostName;
    MyService * theService;

	assert(domainOrService != NULL);

	theService = malloc(sizeof(MyService));
    assert(theService != NULL);
	
	CFStringGetCString(CFNetServiceGetName(domainOrService),   theService->name,    64, kCFStringEncodingUTF8);
    CFStringGetCString(CFNetServiceGetType(domainOrService),   theService->type,   256, kCFStringEncodingUTF8);
    CFStringGetCString(CFNetServiceGetDomain(domainOrService), theService->domain, 256, kCFStringEncodingUTF8);
	
//	NSLog(@"found: %@\n",[NSString stringWithCString:(theService->name) encoding:4]);

	//resolve that address
	MyResolveService(CFNetServiceGetName(domainOrService), CFNetServiceGetType(domainOrService), CFNetServiceGetDomain(domainOrService));
	
	}
		
    return;
}


-(void)CFBonjourPublishWithService:(NSString*)newServiceType machineID:(NSString*)userName onPort:(int)port{

 netService = CFNetServiceCreate(kCFAllocatorDefault, CFSTR(""), (CFStringRef)newServiceType, (CFStringRef)userName, port);

// netService = CFNetServiceCreate(kCFAllocatorDefault, CFSTR(""), (CFStringRef)@"_mrmr._tcp", (CFStringRef)@"AppleiPhone", 1337);
	
    CFNetServiceClientContext clientContext = { 0, NULL, NULL, NULL, NULL };
    CFNetServiceSetClient(netService, netServiceClientCallback, &clientContext);
    CFNetServiceScheduleWithRunLoop(netService, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFStreamError error;
    if (CFNetServiceRegisterWithOptions(netService, kCFNetServiceFlagNoAutoRename, &error) == false) {
        CFNetServiceUnscheduleFromRunLoop(netService, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFNetServiceSetClient(netService, NULL, NULL);
        CFRelease(netService);
        //NSLog(@"Couldn't start service.");
    }
    
    //NSLog(@"Started Bonjour service...");
}


-(void)CFBonjourStopCurrentService{
    NSLog(@"Stopping Bonjour service...");
    CFNetServiceCancel(netService);
    CFNetServiceUnscheduleFromRunLoop(netService, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFNetServiceSetClient(netService, NULL, NULL);
    CFRelease(netService);
	}


-(void)CFBonjourStartBrowsingForServices:(NSString*)serviceType inDomain:(NSString*)domain {

	//NSLog(@"starting BB");
		
	
	MyStartBrowsingForServices(CFStringCreateWithCString(NULL,[serviceType UTF8String],kCFStringEncodingUTF8), CFStringCreateWithCString(NULL,[domain UTF8String],kCFStringEncodingUTF8)); 




	//MyStartBrowsingForServices(kServiceType, kMyDefaultDomain); 
	
}

-(void)countClientsArray{

	//NSLog(@"total bonjour clients: %i",[foundBonjourClients count]);
}


-(NSMutableArray*)CFBonjourClientsArray{

return foundBonjourClients;


}





@end
