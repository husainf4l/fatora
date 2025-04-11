import { ApiProperty } from '@nestjs/swagger';
import { $Enums } from '../../../generated/prisma';

export class UserResponse {
  @ApiProperty({
    description: 'User ID',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  id: string;

  @ApiProperty({
    description: 'User email address',
    example: 'user@example.com',
  })
  email: string;

  @ApiProperty({
    description: 'User first name',
    example: 'John',
    nullable: true,
  })
  firstName: string | null;

  @ApiProperty({
    description: 'User last name',
    example: 'Doe',
    nullable: true,
  })
  lastName: string | null;

  @ApiProperty({
    description: 'User role',
    example: 'USER',
    enum: $Enums.Role,
  })
  role: $Enums.Role;

  @ApiProperty({
    description: 'User creation date',
    example: '2025-04-11T20:34:40.000Z',
  })
  createdAt: Date;

  @ApiProperty({
    description: 'User last update date',
    example: '2025-04-11T20:34:40.000Z',
  })
  updatedAt: Date;
}

export class UserListResponse {
  @ApiProperty({
    description: 'List of users',
    type: [UserResponse],
  })
  users: UserResponse[];
}

export class AuthResponse {
  @ApiProperty({
    description: 'JWT access token',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  })
  access_token: string;

  @ApiProperty({
    description: 'User information',
    type: UserResponse,
  })
  user: Omit<UserResponse, 'createdAt' | 'updatedAt'>;
}