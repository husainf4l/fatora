import { Controller, Get, Post, Body, Param, Delete, Put, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ApiBearerAuth, ApiCreatedResponse, ApiOkResponse, ApiOperation, ApiParam, ApiTags, ApiUnauthorizedResponse } from '@nestjs/swagger';
import { UserResponse, UserListResponse } from '../types/responses/user.responses';

@ApiTags('users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new user' })
  @ApiCreatedResponse({ 
    description: 'The user has been successfully created.',
    type: UserResponse
  })
  create(@Body() createUserDto: CreateUserDto) {
    console.log('Creating user with data:', createUserDto); // Debugging log
    return this.usersService.create(createUserDto);
  }

  @UseGuards(JwtAuthGuard)
  @Get()
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get all users' })
  @ApiOkResponse({ 
    description: 'List of all users.',
    type: [UserResponse]
  })
  @ApiUnauthorizedResponse({ description: 'Unauthorized.' })
  findAll() {
    return this.usersService.findAll();
  }

  @UseGuards(JwtAuthGuard)
  @Get(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiParam({ name: 'id', description: 'User ID', type: 'string' })
  @ApiOkResponse({ 
    description: 'User details.',
    type: UserResponse
  })
  @ApiUnauthorizedResponse({ description: 'Unauthorized.' })
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @UseGuards(JwtAuthGuard)
  @Put(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update user by ID' })
  @ApiParam({ name: 'id', description: 'User ID', type: 'string' })
  @ApiOkResponse({ 
    description: 'User has been successfully updated.',
    type: UserResponse
  })
  @ApiUnauthorizedResponse({ description: 'Unauthorized.' })
  update(@Param('id') id: string, @Body() updateUserDto: Partial<CreateUserDto>) {
    return this.usersService.update(id, updateUserDto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Delete user by ID' })
  @ApiParam({ name: 'id', description: 'User ID', type: 'string' })
  @ApiOkResponse({ 
    description: 'User has been successfully deleted.',
    type: UserResponse
  })
  @ApiUnauthorizedResponse({ description: 'Unauthorized.' })
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
