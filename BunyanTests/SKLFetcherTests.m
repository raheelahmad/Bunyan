//
//  SKLFetcherTests.m
//  Bunyan
//
//  Created by Raheel Ahmad on 3/1/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import "SKLCoreDataTests.h"
#import "SKLTestableAPIClient.h"
#import "SKLManagedObject.h"
#import "SKLTestableManagedObjectContext.h"
#import "SKLRemoteRequestInfo.h"
#import "SKLMockURLSession.h"

// Dependency injected objects
SKLTestableAPIClient *apiClient;
SKLTestableManagedObjectContext *context;
BOOL shouldMockUpdateWithRemoteResponse;

// Returned objects
id responseObject;
NSError *error;

@class SKLFakeOpus;

// ----

@interface SKLFakePerson : SKLManagedObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *location;
@property (nonatomic) NSDate *birthdate;
@property (nonatomic) NSNumber *remoteId;
@property (nonatomic) SKLFakeOpus *magnumOpus;
@property (nonatomic) NSSet *opuses;
@end

@implementation SKLFakePerson

@dynamic name, location, birthdate, remoteId, magnumOpus, opuses;

+ (SKLRemoteRequestInfo *)remoteFetchInfo {
	SKLRemoteRequestInfo *info = [[SKLRemoteRequestInfo alloc] init];
	info.path = @"/get/persons";
	return info;
}

+ (SKLAPIClient *)apiClient {
	return apiClient;
}

- (SKLRemoteRequestInfo *)remoteRefreshInfo {
	SKLRemoteRequestInfo *info = [[SKLRemoteRequestInfo alloc] init];
	info.path = [NSString stringWithFormat:@"/get/persons/%@", self.remoteId];
	
	return info;
}

+ (void)updateWithRemoteFetchResponse:(NSArray *)response {
	if (shouldMockUpdateWithRemoteResponse) {
		responseObject = response;
	} else {
		[super updateWithRemoteFetchResponse:response];
	}
}

- (void)refreshWithRemoteResponse:(NSDictionary *)response {
	if (shouldMockUpdateWithRemoteResponse) {
		responseObject = response;
	} else {
		[super refreshWithRemoteResponse:response];
	}
}

+ (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"remoteId" : @"id",
			 @"name" : @"name",
			 @"location" : @"location",
			 @"birthdate" : @"date",
			 @"magnumOpus" : @"magnum",
			 @"opuses" : @"otherOpuses",
			 };
}

- (id)localValueForKey:(NSString *)localKey RemoteValue:(id)remoteValue {
	id localValue = remoteValue;
	if ([localKey isEqualToString:@"birthdate"]) {
		// 2010-02-06T11:36:49Z
		NSDateFormatter *df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
		localValue = [df dateFromString:remoteValue];
	}
	return localValue;
}

+ (NSManagedObjectContext *)importContext {
	return context;
}

- (NSManagedObjectContext *)managedObjectContext {
	return context;
}

+ (id)uniquingKey {
	return @"remoteId";
}

@end

@interface SKLFakeOpus : SKLManagedObject

@property (nonatomic) NSNumber *remoteId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *pageCount;
@property (nonatomic) SKLFakePerson *magnumOwner;
@property (nonatomic) SKLFakePerson *owner;

@end

@implementation SKLFakeOpus

@dynamic name, pageCount, remoteId, magnumOwner, owner;

+ (NSDictionary *)localToRemoteKeyMapping {
	return @{
			 @"name" : @"name",
			 @"remoteId" : @"id",
			 @"pageCount" : @"pages"
			 };
}

+ (id)uniquingKey { return @"remoteId"; }

@end


// ----

@interface SKLFetcherTests : SKLCoreDataTests

@property (nonatomic) SKLTestableAPIClient *apiClient;
@property (nonatomic) SKLMockURLSession *mockSession;

@end

@implementation SKLFetcherTests

#pragma mark - Refresh Tests

- (void)testRefreshMakesCorrectEndpointAPIRequest {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @212;
	
	[self makePersonRefreshResponse:socrates];
	
	XCTAssertEqualObjects(apiClient.lastRequestPath, @"/get/persons/212", @"Refresh should be made with object's request info path");
}

- (void)testRefreshResponseIsCalled {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @212;
	
	shouldMockUpdateWithRemoteResponse = YES;
	
	[self makePersonRefreshResponse:socrates];
	
	XCTAssertNotNil(responseObject, @"Fetch response should call the model on completion");
}

- (void)testRefreshResponseUpdatesLocalObjects {
	SKLFakePerson *socrates = [SKLFakePerson insertInContext:self.context];
	socrates.remoteId = @210;
	
	[self makePersonRefreshResponse:socrates];
	
	NSDateComponents *dc = [[NSDateComponents alloc] init];
	dc.year = 2012; dc.month = 8; dc.day = 26; dc.hour = 19; dc.minute = 6; dc.second = 43;
	NSDate *socratesBirthDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
	
	[self checkForPersonWithId:@210 hasName:@"Socrates" location:@"Greece" birthdate:socratesBirthDate];
	
	SKLFakeOpus *magnum = socrates.magnumOpus;
	XCTAssertEqualObjects(magnum.name, @"The Republic", @"Refresh should update local object");
	XCTAssertEqualObjects(magnum.pageCount, @443, @"Refresh should update local object");
}


#pragma mark - Fetch Tests

- (void)testFetchMakesCorrectEndpointAPIRequest {
	[SKLFakePerson fetch];
	XCTAssertEqualObjects(apiClient.lastRequestPath, @"/get/persons", @"Fetch should be made with model request info path");
}

- (void)testFetchResponseIsCalled {
	shouldMockUpdateWithRemoteResponse = YES;
	[self makePersonFetchResponse];
	XCTAssertNotNil(responseObject, @"Fetch response should call the model");
}

- (void)testFetchResponseCreatesLocalObjects {
	[self makePersonFetchResponse];
	
	NSArray *people = [SKLFakePerson allInContext:self.context];
	XCTAssertEqual([people count], (NSUInteger)2, @"Should insert objects after fetch");
}

- (void)testFetchResponseCreatesLocalObjectsWithRemoteValues {
	[self makePersonFetchResponse];
	
	NSDateComponents *dc = [[NSDateComponents alloc] init];
	dc.year = 2012; dc.month = 8; dc.day = 26; dc.hour = 19; dc.minute = 6; dc.second = 43;
	NSDate *platoBirthDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
	
	[self checkForPersonWithId:@126 hasName:@"Plato" location:@"Greece" birthdate:platoBirthDate];
	
	dc.year = 2010; dc.month = 02; dc.day = 06; dc.hour = 11; dc.minute = 36; dc.second = 49;
	NSDate *farabiBirthDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
	[self checkForPersonWithId:@120 hasName:@"Al Farabi" location:@"Persia" birthdate:farabiBirthDate];
    
    SKLFakePerson *plato = [[SKLFakePerson allInContext:self.context
											  predicate:[NSPredicate predicateWithFormat:@"remoteId  = %@", @126]] firstObject];
    XCTAssertEqualObjects(plato.name, @"Plato", @"");
}

- (void)testFetchResponseUpdatesExistingLocalObject {
	SKLFakePerson *platoEarlier = [SKLFakePerson insertInContext:self.context];
	platoEarlier.name = @"Plllaatoooo";
	platoEarlier.location = @"Crimea";
	platoEarlier.remoteId = @126; // remoteId will match the remote Plato object
	
	[self makePersonFetchResponse];
	
	NSPredicate *platoPredicate = [NSPredicate predicateWithFormat:@"remoteId == %@", @126];
	NSArray *allPlatos = [SKLFakePerson allInContext:self.context predicate:platoPredicate];
	XCTAssertEqual([allPlatos count], (NSUInteger)1, @"Update should match the existing object");
	SKLFakePerson *platoLater = [allPlatos firstObject];
	XCTAssertEqualObjects(platoLater, platoEarlier, @"Update should match the existing object");
	
	XCTAssertEqualObjects(platoEarlier.name, @"Plato", @"Update should match the existing object");
	
	SKLFakeOpus *magnumOpus = platoLater.magnumOpus;
	XCTAssertEqualObjects(magnumOpus.remoteId, @211, @"Update should update a to-one relationship");
	
	NSArray *otherOpuses = [platoLater.opuses allObjects];
	XCTAssertEqual([otherOpuses count], (NSUInteger)2, @"Update should update a to-many relationship");
}

#pragma mark - Helpers

- (void)checkForPersonWithId:(NSNumber *)remoteId
					 hasName:(NSString *)name
					location:(NSString *)location
				   birthdate:(NSDate *)birthdate {
	NSPredicate *singlePersonPredicate = [NSPredicate predicateWithFormat:@"remoteId == %@", remoteId];
	SKLFakePerson *plato = [[SKLFakePerson allInContext:self.context predicate:singlePersonPredicate] firstObject];
	XCTAssertEqualObjects(plato.name, name, @"Remote fetch response should create local object with remote values");
	XCTAssertEqualObjects(plato.location, location, @"Remote fetch response should create local object with remote values");
	XCTAssertEqualObjects(plato.birthdate, birthdate, @"Remote fetch response should create local object with remote values");
}

- (void)makePersonFetchResponse {
	self.context.shouldPerformBlockAsSync = YES;
	[SKLFakePerson fetch];
	
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
	NSArray *personFetchResponse = @[
									 @{ @"id" : @120, @"name" : @"Al Farabi", @"location" : @"Persia", @"date" : @"2010-02-06T11:36:49Z" },
									 @{ @"id" : @126, @"name" : @"Plato", @"location" : @"Greece", @"date" : @"2012-08-26T19:06:43Z",
										@"magnum" : @{
												@"id" : @211, @"name" : @"The Republic", @"pages" : @443
												},
										@"otherOpuses" : @[
                                                @{
													@"id" : @214, @"name" : @"Dramas", @"pages" : @204
													},
                                                @{
													@"id" : @204, @"name" : @"Interlooction", @"pages" : @123
													}
												]
                                        },
									 ];
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:personFetchResponse options:0 error:nil];
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
															  statusCode:200
															 HTTPVersion:@"1.1"
															headerFields:jsonResponseHeaderDict];
	apiClient.mockSession.lastCompletionHandler(responseData, response, nil);
}

- (void)makePersonRefreshResponse:(SKLFakePerson *)person {
	self.context.shouldPerformBlockAsSync = YES;
	[person refresh];
	
    NSDictionary *jsonResponseHeaderDict = @{ @"Content-Type" : @"application/json" };
	NSDictionary *personRefreshResponse = @{ @"id" : person.remoteId, @"name" : @"Socrates", @"location" : @"Greece", @"date" : @"2012-08-26T19:06:43Z",
										@"magnum" : @{
												@"id" : @211, @"name" : @"The Republic", @"pages" : @443
												},
										@"otherOpuses" : @[
                                                @{
													@"id" : @214, @"name" : @"Dramas", @"pages" : @204
													},
                                                @{
													@"id" : @204, @"name" : @"Interlooction", @"pages" : @123
													}
												]
                                        };
	NSData *responseData = [NSJSONSerialization dataWithJSONObject:personRefreshResponse options:0 error:nil];
	NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
															  statusCode:200
															 HTTPVersion:@"1.1"
															headerFields:jsonResponseHeaderDict];
	apiClient.mockSession.lastCompletionHandler(responseData, response, nil);
}


#pragma mark - Setup

- (NSManagedObjectModel *)loadCustomModel {
	NSEntityDescription *personEntity = [self entityWithName:NSStringFromClass([SKLFakePerson class])
												  attributes:@[
															   @{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
															   @{ SKLAttrNameKey : @"location", SKLAttrTypeKey : @"string" },
															   @{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" },
															   @{ SKLAttrNameKey : @"birthdate", SKLAttrTypeKey : @"date" }
															   ]
										 ];
	NSEntityDescription *opusEntity = [self entityWithName:NSStringFromClass([SKLFakeOpus class])
												attributes:@[
															 @{ SKLAttrNameKey : @"name", SKLAttrTypeKey : @"string" },
															 @{ SKLAttrNameKey : @"remoteId", SKLAttrTypeKey : @"int" },
															 @{ SKLAttrNameKey : @"pageCount", SKLAttrTypeKey : @"int" }
															 ]
									   ];
	addRelationships(personEntity, opusEntity, @"magnumOpus", @"magnumOwner", NO, NO);
	addRelationships(personEntity, opusEntity, @"opuses", @"owner", YES, NO);
	
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
    model.entities = @[ personEntity, opusEntity ];
    return model;
}


- (void)setUp {
    [super setUp];
	
	shouldMockUpdateWithRemoteResponse = NO;
	context = self.context;
	self.apiClient = [[SKLTestableAPIClient alloc] initWithBaseURL:@"http://sakunlabs.com"];
	self.apiClient.mockSession = [[SKLMockURLSession alloc] init];
	
	apiClient = self.apiClient;
}

- (void)tearDown {
	error = nil;
	self.context = nil;
	
	[super tearDown];
}

@end
