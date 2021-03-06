//
//  ZNModelDefinitionAttribute.m
//  ZergSupport
//
//  Created by Victor Costan on 1/14/09.
//  Copyright Zergling.Net. Licensed under the MIT license.
//

#import "ZNModelDefinitionAttribute.h"

#import "ZNMSAttributeType.h"

@implementation ZNModelDefinitionAttribute

@synthesize name, getterName, setterName, type, runtimeIvar;
@synthesize isAtomic, isReadOnly, setterStrategy;

-(id)initWithName:(NSString*)theName
             type:(ZNMSAttributeType*)theType
      runtimeIvar:(Ivar)theIvar
         isAtomic:(BOOL)theIsAtomic
       isReadOnly:(BOOL)theIsReadOnly
       getterName:(NSString*)theGetter
       setterName:(NSString*)theSetter
   setterStrategy:(enum ZNPropertySetterStrategy)theStrategy {
  if ((self = [super init])) {
    name = [theName retain];
    getterName = [theGetter retain];
    setterName = [theSetter retain];
    type = [theType retain];
    runtimeIvar = theIvar;
    isAtomic = theIsAtomic;
    isReadOnly = theIsReadOnly;
    setterStrategy = theStrategy;
  }
  return self;
}

-(void)dealloc {
  [name release];
  [getterName release];
  [setterName release];
  [type release];
  [super dealloc];
}

+(ZNModelDefinitionAttribute*)newAttributeFromProperty:(objc_property_t)property
                                               ofClass:(Class)klass {
  ZNModelDefinitionAttribute* attribute; // Initialized at the done: label.

  const char* propertyNameCString = property_getName(property);
  NSString* propertyName =
      [[NSString alloc] initWithBytes:propertyNameCString
                               length:strlen(propertyNameCString)
                             encoding:NSASCIIStringEncoding];
  const char* propertyAttributes = property_getAttributes(property);

  NSAssert(*propertyAttributes == 'T', @"Property attributes format changed");
  propertyAttributes++;

  Ivar runtimeIvar = class_getInstanceVariable(klass, propertyNameCString);

  // Property type

  ZNMSAttributeType* attributeType = [ZNMSAttributeType
                                      copyTypeFromString:propertyAttributes];

  const char* typeComma = strchr(propertyAttributes, ',');
  if (typeComma)
    propertyAttributes = typeComma;
  else
    propertyAttributes += strlen(propertyAttributes);


  // Property properties

  BOOL isReadOnly = NO;
  BOOL isAtomic = NO;
  NSString* getterName = nil;
  NSString* setterName = nil;
  enum ZNPropertySetterStrategy setterStrategy = kZNPropertyWantsAssign;

  for (; *propertyAttributes; propertyAttributes++) {
    switch (*propertyAttributes) {
      case ',':
        // separates attributes
        break;
      case 'R':
        isReadOnly = YES;
        break;
      case 'C':
        setterStrategy = kZNPropertyWantsCopy;
        break;
      case '&':
        setterStrategy = kZNPropertyWantsRetain;
        break;
      case 'G':
      case 'S': {
        const char* xetterComma = strchr(propertyAttributes + 1, ',');
        size_t xetterLength = (xetterComma ? xetterComma - propertyAttributes :
            strlen(propertyAttributes)) - 1;
        NSString* xetter = [[NSString alloc]
                            initWithBytes:(propertyAttributes + 1)
                            length:xetterLength
                            encoding:NSASCIIStringEncoding];
        if (*propertyAttributes == 'G') {
          NSAssert(!getterName, @"Getter parsed twice in property descriptor");
          getterName = xetter;
        }
        else {
          NSAssert(!setterName, @"Setter parsed twice in property descriptor");
          setterName = xetter;
        }
        propertyAttributes += xetterLength;  // incremented by for loop, as well
        break;
      }
      default: {
        // unknown attribute
        const char* attrComma = strchr(propertyAttributes + 1, ',');
        if (attrComma)
          propertyAttributes = attrComma;
        else
          goto done;
      }
    }
  }

done:
  attribute =
      [[ZNModelDefinitionAttribute alloc]
       initWithName:propertyName
       type:attributeType
       runtimeIvar:runtimeIvar
       isAtomic:isAtomic
       isReadOnly:isReadOnly
       getterName:getterName
       setterName:setterName
       setterStrategy:setterStrategy];
  [propertyName release];
  [attributeType release];
  [getterName release];
  [setterName release];
  return attribute;
}

@end
